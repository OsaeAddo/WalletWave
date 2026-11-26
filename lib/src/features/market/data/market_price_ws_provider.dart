import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/network/backoff.dart';

// Provides a map of symbol -> live price (e.g., {'btc': 60500.20, 'eth': 3100.50})
final livePricesProvider =
    NotifierProvider<LivePricesNotifier, Map<String, double>>(
  LivePricesNotifier.new,
);

class LivePricesNotifier extends Notifier<Map<String, double>> {
  static final _tickerUri =
      Uri.parse('wss://stream.binance.com:9443/ws/!miniTicker@arr');

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  bool _disposed = false;

  /// Consecutive failed connection attempts; reset by the first live message.
  int _attempt = 0;

  @override
  Map<String, double> build() {
    ref.onDispose(() {
      // Mark first, so any late stream callback cannot schedule a reconnect.
      _disposed = true;
      _reconnectTimer?.cancel();
      _channel?.sink.close();
    });

    _connect();
    return {}; // Initial state is an empty cache
  }

  void _connect() {
    if (_disposed) return;

    _channel = WebSocketChannel.connect(_tickerUri);
    _channel!.stream.listen(
      _handleMessage,
      onError: (_) => _scheduleReconnect(),
      onDone: _scheduleReconnect,
      cancelOnError: true,
    );
  }

  void _handleMessage(dynamic message) {
    // Traffic proves the socket works, so the next outage starts from 2s again.
    _attempt = 0;

    final List<dynamic> data = jsonDecode(message as String);
    final Map<String, double> newPrices = {...state};
    var hasChanges = false;

    for (final item in data) {
      final symbol = item['s'] as String;

      // We only track USDT pairs to match our USD fiat base
      if (symbol.endsWith('USDT')) {
        // Convert Binance 'BTCUSDT' to CoinGecko 'btc'
        final baseSymbol = symbol.replaceAll('USDT', '').toLowerCase();
        final price = double.tryParse(item['c'] as String);

        if (price != null && newPrices[baseSymbol] != price) {
          newPrices[baseSymbol] = price;
          hasChanges = true;
        }
      }
    }

    // Only trigger a state update if relevant coins actually moved
    if (hasChanges) {
      state = newPrices;
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;

    // `onError` and `onDone` can both fire for the same failure. Scheduling
    // twice would skip an attempt and jump the delay, so keep only the first.
    if (_reconnectTimer?.isActive ?? false) return;

    final delay = reconnectDelay(_attempt);
    _attempt++;

    _reconnectTimer = Timer(delay, _connect);
  }
}
