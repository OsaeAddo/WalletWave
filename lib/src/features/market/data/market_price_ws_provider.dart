import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Provides a map of symbol -> live price (e.g., {'btc': 60500.20, 'eth': 3100.50})
final livePricesProvider =
    NotifierProvider<LivePricesNotifier, Map<String, double>>(
  LivePricesNotifier.new,
);

class LivePricesNotifier extends Notifier<Map<String, double>> {
  WebSocketChannel? _channel;

  @override
  Map<String, double> build() {
    _connect();

    // Clean up the network resource when the provider is disposed
    ref.onDispose(() {
      _channel?.sink.close();
    });

    return {}; // Initial state is an empty cache
  }

  void _connect() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://stream.binance.com:9443/ws/!miniTicker@arr'),
    );

    _channel!.stream.listen(
      (dynamic message) {
        final List<dynamic> data = jsonDecode(message as String);
        final Map<String, double> newPrices = {...state};
        bool hasChanges = false;

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
      },
      onError: (error) {
        // Implement exponential backoff in a true production app
        Future.delayed(const Duration(seconds: 5), _connect);
      },
      onDone: () {
        // Handle server-side disconnects
        Future.delayed(const Duration(seconds: 5), _connect);
      },
    );
  }
}
