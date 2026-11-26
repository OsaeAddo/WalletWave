import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/portfolio/data/neon_realtime_client.dart';

/// Captures outgoing frames and lets the test play the server.
class _FakeSocket implements RealtimeSocket {
  final _incoming = StreamController<String>();
  final sent = <Map<String, dynamic>>[];
  bool closed = false;

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void send(String message) {
    sent.add(jsonDecode(message) as Map<String, dynamic>);
  }

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  void server(Map<String, dynamic> message) {
    _incoming.add(jsonEncode(message));
  }
}

/// Gives the client's async connect a chance to subscribe to the fake socket.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  const columns = [
    {'name': 'id', 'type_oid': 20, 'typmod': -1, 'codec': 'pg_text'},
    {'name': 'op', 'type_oid': 25, 'typmod': -1, 'codec': 'pg_text'},
    {'name': 'changed_at', 'type_oid': 1184, 'typmod': -1, 'codec': 'pg_text'},
  ];

  RealtimeTicket ticket({Duration? lifetime}) => RealtimeTicket(
        capability: 'capability',
        queryFingerprint: 'fingerprint',
        expiresAt:
            DateTime.now().toUtc().add(lifetime ?? const Duration(hours: 1)),
      );

  Future<void> handshake(_FakeSocket socket) async {
    socket.server({'type': 'ready'});
    await settle();
    socket.server({
      'type': 'subscribed',
      'request_id': '1',
      'live_id': '7',
      'epoch': '1',
      'first_sequence': '1',
      'columns': columns,
    });
    await settle();
  }

  Map<String, dynamic> baselineStart() => {
        'type': 'baseline_sync_start',
        'live_id': '7',
        'epoch': '1',
        'baseline_sync_attempt': '1',
        'mvcc': {'xmin': '0', 'xmax': '0', 'xip': <dynamic>[]},
      };

  Map<String, dynamic> baselineBatch(List<Map<String, dynamic>> rows) => {
        'type': 'baseline_sync_batch',
        'live_id': '7',
        'epoch': '1',
        'baseline_sync_attempt': '1',
        'index': 0,
        'rows': rows,
      };

  test('handshake, subscribe and baseline produce live rows', () async {
    final socket = _FakeSocket();
    final updates = <SavedWalletFeedUpdate>[];
    final client = NeonRealtimeClient(
      url: Uri.parse('wss://realtime.example/'),
      fetchTicket: () async => ticket(),
      socketFactory: (url, protocols) async {
        expect(url.toString(), 'wss://realtime.example/');
        expect(protocols, ['neon.realtime.v2']);
        return socket;
      },
    );
    final subscription = client.updates.listen(updates.add);
    addTearDown(() async {
      await subscription.cancel();
      await client.dispose();
    });

    client.start();
    await settle();
    await handshake(socket);

    final sentTypes = socket.sent.map((message) => message['type']).toList();
    expect(sentTypes, containsAllInOrder(['client_info', 'subscribe']));
    expect(socket.sent.last['authorization'], 'capability');

    socket.server(baselineStart());
    socket.server(
      baselineBatch([
        {
          'row_key': '8',
          'values': ['8', 'insert', '2026-11-24T12:00:00.000Z'],
        },
        {
          'row_key': '7',
          'values': ['7', 'update', '2026-11-24T11:00:00.000Z'],
        },
      ]),
    );
    socket.server({
      'type': 'baseline_sync_end',
      'live_id': '7',
      'epoch': '1',
      'baseline_sync_attempt': '1',
      'batch_count': 1,
    });
    await settle();

    final live = updates.last;
    expect(live.status, SavedWalletFeedStatus.live);
    expect(live.rows.map((row) => row.id), [8, 7]);
    expect(live.latest?.op, 'insert');
    expect(live.latest?.changedAt, DateTime.utc(2026, 11, 24, 12));
  });

  test('a committed insert moves to the head and removes evicted rows',
      () async {
    final socket = _FakeSocket();
    final updates = <SavedWalletFeedUpdate>[];
    final client = NeonRealtimeClient(
      url: Uri.parse('wss://realtime.example/'),
      fetchTicket: () async => ticket(),
      socketFactory: (url, protocols) async => socket,
    );
    final subscription = client.updates.listen(updates.add);
    addTearDown(() async {
      await subscription.cancel();
      await client.dispose();
    });

    client.start();
    await settle();
    await handshake(socket);
    socket.server(baselineStart());
    socket.server(
      baselineBatch([
        {
          'row_key': '5',
          'values': ['5', 'insert', '2026-11-24T10:00:00Z'],
        },
        {
          'row_key': '4',
          'values': ['4', 'insert', '2026-11-24T09:00:00Z'],
        },
      ]),
    );
    socket.server({
      'type': 'baseline_sync_end',
      'live_id': '7',
      'epoch': '1',
      'baseline_sync_attempt': '1',
      'batch_count': 1,
    });
    await settle();

    socket.server({
      'type': 'open',
      'publication_id': 'pub-1',
    });
    socket.server({
      'type': 'keyed_results',
      'publication_id': 'pub-1',
      'index': 0,
      'txids': ['100'],
      'targets': [
        {'live_id': '7', 'epoch': '1', 'sequence': '1'},
      ],
      'changes': [
        {
          'op': 'move',
          'row_key': '6',
          'after_row_key': null,
        },
        {
          'op': 'upsert',
          'row_key': '6',
          'values': ['6', 'insert', '2026-11-24T13:00:00Z'],
        },
        {
          'op': 'remove',
          'row_key': '4',
        },
      ],
    });
    socket.server({
      'type': 'commit',
      'publication_id': 'pub-1',
      'body_count': 1,
      'frontier': {'lsn': '0/1'},
    });
    await settle();

    final latest = updates.last;
    expect(latest.status, SavedWalletFeedStatus.live);
    expect(latest.rows.map((row) => row.id), [6, 5]);
  });

  test('renews the capability before it expires', () async {
    final socket = _FakeSocket();
    var tickets = 0;
    final client = NeonRealtimeClient(
      url: Uri.parse('wss://realtime.example/'),
      fetchTicket: () async {
        tickets += 1;
        return ticket(
          lifetime: const Duration(milliseconds: 500),
        );
      },
      socketFactory: (url, protocols) async => socket,
      renewalMargin: const Duration(milliseconds: 100),
    );
    addTearDown(client.dispose);

    client.start();
    await settle();
    await handshake(socket);

    // Wait past the renewal point, but well before the capability expires.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(tickets, greaterThanOrEqualTo(2));
    final renew = socket.sent.where((message) => message['type'] == 'renew');
    expect(renew, isNotEmpty);
    expect(renew.last['live_id'], '7');
  });

  test('answers server pings so the connection stays alive', () async {
    final socket = _FakeSocket();
    final client = NeonRealtimeClient(
      url: Uri.parse('wss://realtime.example/'),
      fetchTicket: () async => ticket(),
      socketFactory: (url, protocols) async => socket,
    );
    addTearDown(client.dispose);

    client.start();
    await settle();
    await handshake(socket);

    socket.server({'type': 'ping', 'token': 'server-1'});
    await settle();

    final pong = socket.sent.last;
    expect(pong['type'], 'pong');
    expect(pong['token'], 'server-1');
  });
}
