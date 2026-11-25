import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

/// The WebSocket subprotocol Neon Realtime speaks.
const realtimeSubprotocol = 'neon.realtime.v2';

/// One short-lived sealed capability returned by `POST /realtime/ticket`.
///
/// It is a bearer credential for exactly one query, already filtered to the
/// signed-in user. It is never persisted: a new one is fetched before expiry.
class RealtimeTicket {
  const RealtimeTicket({
    required this.capability,
    required this.queryFingerprint,
    required this.expiresAt,
  });

  factory RealtimeTicket.fromJson(Map<String, dynamic> json) {
    final capability = json['capability'];
    final fingerprint = json['queryFingerprint'];
    final expiresAt = json['expiresAt'];
    if (capability is! String || fingerprint is! String || expiresAt is! num) {
      throw const FormatException('Malformed realtime ticket');
    }
    return RealtimeTicket(
      capability: capability,
      queryFingerprint: fingerprint,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        expiresAt.toInt(),
        isUtc: true,
      ),
    );
  }

  final String capability;
  final String queryFingerprint;
  final DateTime expiresAt;
}

/// The connection state of the live wallet feed.
enum SavedWalletFeedStatus { connecting, live, error }

/// One row from the `saved_wallets_events` change feed.
class SavedWalletChange {
  const SavedWalletChange({
    required this.id,
    required this.op,
    required this.changedAt,
  });

  final int id;

  /// `insert`, `update` or `delete`.
  final String op;

  final DateTime? changedAt;
}

/// A snapshot of the feed after the connection, a baseline, or a change.
class SavedWalletFeedUpdate {
  const SavedWalletFeedUpdate({
    required this.status,
    this.rows = const [],
    this.message,
  });

  final SavedWalletFeedStatus status;

  /// Current rows, newest first.
  final List<SavedWalletChange> rows;

  /// Human-readable error, set when [status] is [SavedWalletFeedStatus.error].
  final String? message;

  SavedWalletChange? get latest => rows.isEmpty ? null : rows.first;
}

/// Small transport seam so the protocol can be tested without a socket.
abstract interface class RealtimeSocket {
  Stream<String> get messages;

  void send(String message);

  Future<void> close();
}

typedef RealtimeSocketFactory = Future<RealtimeSocket> Function(
  Uri url,
  List<String> protocols,
);

/// A [RealtimeSocket] backed by `package:web_socket_channel`.
class WebSocketRealtimeSocket implements RealtimeSocket {
  WebSocketRealtimeSocket(this._channel);

  final WebSocketChannel _channel;

  @override
  Stream<String> get messages => _channel.stream.map(
        (message) =>
            message is String ? message : utf8.decode(message as List<int>),
      );

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() => _channel.sink.close();
}

Future<RealtimeSocket> _connectWebSocket(
  Uri url,
  List<String> protocols,
) async {
  final channel = WebSocketChannel.connect(url, protocols: protocols);
  // `ready` completes (or throws) once the handshake and subprotocol
  // negotiation finish, so callers can surface a real error.
  await channel.ready;
  return WebSocketRealtimeSocket(channel);
}

/// Minimal Neon Realtime protocol v2 client for one sealed query.
///
/// Neon ships a JavaScript SDK but no Dart one, so this implements the wire
/// protocol directly. Only the parts WalletWave needs are materialized: the
/// rows are kept in server order (newest first) so the UI can show the latest
/// operation, while the wallet list itself is still re-read through the Data
/// API, where Row Level Security applies.
///
/// The client reconnects with capped, jittered backoff, answers heartbeats, and
/// renews its capability before it expires.
class NeonRealtimeClient {
  NeonRealtimeClient({
    required Uri url,
    required Future<RealtimeTicket?> Function() fetchTicket,
    RealtimeSocketFactory? socketFactory,
    DateTime Function()? clock,
    Duration renewalMargin = const Duration(seconds: 10),
    this.heartbeatInterval = const Duration(seconds: 20),
    this.heartbeatTimeout = const Duration(seconds: 10),
  })  : _url = url,
        _fetchTicket = fetchTicket,
        _socketFactory = socketFactory ?? _connectWebSocket,
        _clock = clock ?? DateTime.now,
        _renewalMargin = renewalMargin;

  final Uri _url;
  final Future<RealtimeTicket?> Function() _fetchTicket;
  final RealtimeSocketFactory _socketFactory;
  final DateTime Function() _clock;
  final Duration _renewalMargin;
  final Duration heartbeatInterval;
  final Duration heartbeatTimeout;

  final _updates = StreamController<SavedWalletFeedUpdate>.broadcast();
  final _rows = <String, List<String?>>{};
  final _pendingChanges = <Map<String, dynamic>>[];

  RealtimeSocket? _socket;
  StreamSubscription<String>? _frames;
  RealtimeTicket? _ticket;

  Timer? _reconnectTimer;
  Timer? _renewTimer;
  Timer? _heartbeatTimer;
  Timer? _pongTimer;

  List<_Column> _columns = const [];
  String? _liveId;
  int _requestCounter = 0;
  int _attempt = 0;
  int _heartbeatCounter = 0;

  bool _started = false;
  bool _disposed = false;
  bool _connecting = false;
  bool _ready = false;
  bool _renewing = false;

  /// Current feed snapshots, emitted on status changes and row changes.
  Stream<SavedWalletFeedUpdate> get updates => _updates.stream;

  /// Opens the connection if it is not already open or opening.
  void start() {
    if (_disposed || _started) return;
    _started = true;
    unawaited(_connect());
  }

  Future<void> _connect() async {
    if (_disposed || _connecting) return;
    _connecting = true;
    _resetProtocolState();
    _emit(SavedWalletFeedStatus.connecting);

    try {
      final ticket = await _fetchTicket();
      if (_disposed) return;
      if (ticket == null) {
        _emit(
          SavedWalletFeedStatus.error,
          message: 'Sign in to sync saved wallets.',
        );
        return;
      }
      _ticket = ticket;

      final socket = await _socketFactory(_url, const [realtimeSubprotocol]);
      if (_disposed) {
        await socket.close();
        return;
      }
      _socket = socket;
      _frames = socket.messages.listen(
        _receive,
        onError: (Object error) {
          if (identical(_socket, socket)) _disconnected(_friendly(error));
        },
        onDone: () {
          if (identical(_socket, socket)) {
            _disconnected('Live sync disconnected.');
          }
        },
      );
    } catch (error) {
      _disconnected(_friendly(error));
    } finally {
      _connecting = false;
    }
  }

  void _disconnected(String message) {
    if (_disposed) return;
    _cancelTimers();
    final frames = _frames;
    final socket = _socket;
    _frames = null;
    _socket = null;
    _ready = false;
    _liveId = null;
    _resetProtocolState();

    unawaited(frames?.cancel());

    // Closing here is best-effort; the socket may already be gone.
    if (socket != null) {
      unawaited(socket.close().catchError((_) {}));
    }

    if (!_started) return;
    _emit(SavedWalletFeedStatus.error, message: message);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _reconnectTimer != null) return;
    // 1s, 2s, 4s, 8s, 16s, then 30s, plus up to 500 ms of jitter so many
    // clients do not retry in lockstep after an outage.
    final seconds = min(30, 1 << min(_attempt, 5));
    _attempt += 1;
    final jitter = Random().nextInt(500);
    _reconnectTimer = Timer(
      Duration(seconds: seconds, milliseconds: jitter),
      () {
        _reconnectTimer = null;
        unawaited(_connect());
      },
    );
  }

  void _receive(String text) {
    if (_disposed) return;
    _markAlive();

    dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } catch (_) {
      // A malformed frame is not actionable; the protocol validator in the
      // JS client is strict, but dropping is safer than tearing down here.
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    final message = decoded;

    final type = message['type'];
    if (type is! String) return;

    if (!_ready) {
      if (type == 'ping') {
        _send({'type': 'pong', 'token': message['token']});
        return;
      }
      if (type != 'ready') {
        _disconnected('Unexpected handshake message.');
        return;
      }
      _ready = true;
      _send({
        'type': 'client_info',
        'metadata': jsonEncode({
          'sdk': 'dart',
          'release_line': '0.1',
          'version': '0.1.0',
        }),
      });
      _startHeartbeat();
      _subscribe();
      return;
    }

    switch (type) {
      case 'ping':
        _send({'type': 'pong', 'token': message['token']});
        break;
      case 'pong':
        _pongTimer?.cancel();
        _pongTimer = null;
        break;
      case 'subscribed':
        _onSubscribed(message);
        break;
      case 'subscribe_rejected':
        _onSubscribeRejected(message);
        break;
      case 'renewed':
        _renewing = false;
        _emit(SavedWalletFeedStatus.live);
        break;
      case 'unsubscribed':
        _liveId = null;
        break;
      case 'baseline_sync_start':
        _rows.clear();
        break;
      case 'baseline_sync_batch':
        _appendBaseline(message);
        break;
      case 'baseline_sync_end':
        _emit(SavedWalletFeedStatus.live);
        break;
      case 'open':
        _pendingChanges.clear();
        break;
      case 'keyed_results':
        _collectChanges(message);
        break;
      case 'reset_required':
        // The server follows this with a fresh baseline; keep the connection.
        _emit(SavedWalletFeedStatus.connecting);
        break;
      case 'commit':
        _applyPendingChanges();
        _emit(SavedWalletFeedStatus.live);
        break;
      case 'subscription_error':
        _onSubscriptionError(message);
        break;
      case 'connection_error':
        _disconnected(
          _string(message['message']) ?? 'The live feed stopped.',
        );
        break;
      case 'client_warning':
        // Warnings are informational; the feed keeps working.
        break;
      case 'ready':
        _disconnected('The server sent a duplicate handshake.');
        break;
      default:
        // Unknown frame types are ignored so a protocol addition does not
        // break older clients.
        break;
    }
  }

  void _subscribe() {
    final ticket = _ticket;
    if (!_ready || ticket == null) return;
    _requestCounter += 1;
    _send({
      'type': 'subscribe',
      'request_id': '$_requestCounter',
      'authorization': ticket.capability,
    });
    _scheduleRenewal();
  }

  void _onSubscribed(Map<String, dynamic> message) {
    final liveId = _string(message['live_id']);
    final firstSequence =
        int.tryParse(_string(message['first_sequence']) ?? '');
    final columns = message['columns'];
    if (liveId == null || firstSequence == null) {
      _disconnected('The live feed sent an invalid subscription.');
      return;
    }
    _liveId = liveId;
    _attempt = 0;
    _columns = [
      if (columns is List)
        for (final column in columns)
          if (column is Map && column['name'] is String)
            _Column(name: column['name'] as String),
    ];
  }

  void _onSubscribeRejected(Map<String, dynamic> message) {
    final code = _string(message['code']);
    final detail = _string(message['message']) ?? 'Subscription rejected.';
    if (code == 'authorization_expired') {
      // The capability went stale before we renewed. Fetch a new one.
      _ticket = null;
      unawaited(_renew());
      return;
    }
    _disconnected(detail);
  }

  void _onSubscriptionError(Map<String, dynamic> message) {
    final code = _string(message['code']);
    final detail = _string(message['message']) ?? 'The live feed failed.';
    if (code == 'authorization_expired') {
      unawaited(_renew());
      return;
    }
    _disconnected(detail);
  }

  void _appendBaseline(Map<String, dynamic> message) {
    final rows = message['rows'];
    if (rows is! List) return;
    for (final row in rows) {
      if (row is! Map) continue;
      final key = _string(row['row_key']);
      final values = row['values'];
      if (key == null || values is! List) continue;
      _rows[key] = [
        for (final value in values) _cell(value),
      ];
    }
  }

  void _collectChanges(Map<String, dynamic> message) {
    final targets = message['targets'];
    if (targets is! List) return;
    final mentionsUs = targets.any(
      (target) => target is Map && _string(target['live_id']) == _liveId,
    );
    if (!mentionsUs) return;
    final changes = message['changes'];
    if (changes is! List) return;
    for (final change in changes) {
      if (change is Map<String, dynamic>) _pendingChanges.add(change);
    }
  }

  void _applyPendingChanges() {
    if (_pendingChanges.isEmpty) return;
    final changes = List<Map<String, dynamic>>.of(_pendingChanges);
    _pendingChanges.clear();

    // Mirrors the JS client's materializer: contents first, then moves.
    for (final change in changes) {
      final op = change['op'];
      final key = _string(change['row_key']);
      if (key == null) continue;
      if (op == 'remove') {
        _rows.remove(key);
      } else if (op == 'upsert') {
        final values = change['values'];
        if (values is List) {
          _rows[key] = [for (final value in values) _cell(value)];
        }
      }
    }

    final moves = [
      for (final change in changes)
        if (change['op'] == 'move') change,
    ];
    if (moves.isEmpty) return;

    var entries = _rows.entries.toList();
    for (final move in moves) {
      final key = _string(move['row_key']);
      if (key == null) continue;
      final anchor = _string(move['after_row_key']);
      final entry = entries.where((item) => item.key == key).firstOrNull;
      if (entry == null) continue;
      entries = [
        for (final item in entries)
          if (item.key != key) item,
      ];
      final at = anchor == null
          ? 0
          : entries.indexWhere((item) => item.key == anchor) + 1;
      entries.insert(at <= 0 ? 0 : at, MapEntry(key, entry.value));
    }
    _rows
      ..clear()
      ..addEntries(entries);
  }

  void _scheduleRenewal() {
    _renewTimer?.cancel();
    final ticket = _ticket;
    if (ticket == null || _disposed) return;
    final remaining = ticket.expiresAt.difference(_clock().toUtc());
    final delay = remaining - _renewalMargin;
    _renewTimer = Timer(
      delay.isNegative ? const Duration(seconds: 1) : delay,
      () => unawaited(_renew()),
    );
  }

  Future<void> _renew() async {
    if (_disposed || _renewing) return;
    _renewing = true;
    try {
      final ticket = await _fetchTicket();
      if (_disposed) return;
      if (ticket == null) {
        _disconnected('Sign in to sync saved wallets.');
        return;
      }
      _ticket = ticket;
      final liveId = _liveId;
      if (!_ready) {
        _subscribe();
      } else if (liveId != null) {
        _send({
          'type': 'renew',
          'live_id': liveId,
          'authorization': ticket.capability,
        });
      } else {
        _subscribe();
      }
      _scheduleRenewal();
    } catch (_) {
      // Retry while the old capability may still be valid.
      _renewTimer = Timer(
        const Duration(seconds: 5),
        () {
          _renewing = false;
          unawaited(_renew());
        },
      );
      return;
    } finally {
      _renewing = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer(heartbeatInterval, _sendPing);
  }

  void _markAlive() {
    if (!_ready || _disposed) return;
    _pongTimer?.cancel();
    _pongTimer = null;
    _startHeartbeat();
  }

  void _sendPing() {
    if (_disposed || !_ready) return;
    _heartbeatCounter += 1;
    _send({'type': 'ping', 'token': 'c$_heartbeatCounter'});
    _pongTimer = Timer(heartbeatTimeout, () {
      _disconnected('The live feed stopped responding.');
    });
  }

  void _send(Map<String, dynamic> message) {
    final socket = _socket;
    if (socket == null) return;
    try {
      socket.send(jsonEncode(message));
    } catch (_) {
      // The socket is closing; its done callback will handle recovery.
    }
  }

  void _resetProtocolState() {
    _ready = false;
    _liveId = null;
    _requestCounter = 0;
    _rows.clear();
    _pendingChanges.clear();
    _columns = const [];
  }

  void _cancelTimers() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _renewTimer?.cancel();
    _renewTimer = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _pongTimer?.cancel();
    _pongTimer = null;
    _renewing = false;
  }

  void _emit(SavedWalletFeedStatus status, {String? message}) {
    if (_disposed) return;
    final rows = <SavedWalletChange>[];
    for (final entry in _rows.entries) {
      final change = _change(entry.key, entry.value);
      if (change != null) rows.add(change);
    }
    rows.sort((a, b) => b.id.compareTo(a.id));
    _updates.add(
      SavedWalletFeedUpdate(status: status, rows: rows, message: message),
    );
  }

  SavedWalletChange? _change(String rowKey, List<String?> values) {
    final byName = <String, String?>{
      for (var index = 0;
          index < _columns.length && index < values.length;
          index++)
        _columns[index].name: values[index],
    };
    final id = int.tryParse(byName['id'] ?? rowKey);
    if (id == null) return null;
    return SavedWalletChange(
      id: id,
      op: byName['op'] ?? '',
      changedAt: DateTime.tryParse(byName['changed_at'] ?? ''),
    );
  }

  String? _cell(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is Map && value['base64'] is String) {
      try {
        return utf8.decode(base64Decode(value['base64'] as String));
      } catch (_) {
        return null;
      }
    }
    return value.toString();
  }

  String? _string(Object? value) => value is String ? value : null;

  String _friendly(Object error) {
    // DioException and SocketException read poorly in the UI.
    return 'Live sync is offline. It will retry automatically.';
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _started = false;
    _cancelTimers();
    await _frames?.cancel();
    _frames = null;
    final socket = _socket;
    _socket = null;
    if (socket != null) {
      try {
        await socket.close();
      } catch (_) {
        // Already closed.
      }
    }
    await _updates.close();
  }
}

class _Column {
  const _Column({required this.name});

  final String name;
}
