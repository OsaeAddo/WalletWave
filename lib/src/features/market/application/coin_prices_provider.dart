import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/market_price_ws_provider.dart';
import 'market_providers.dart';

/// Current USD price per lowercase symbol, e.g. `{'eth': 3100.5}`.
///
/// Two sources are merged:
/// 1. The cached/fetched market list (CoinGecko). It survives offline and is
///    the fallback when the socket has not ticked yet.
/// 2. The Binance WebSocket feed. It is fresher, so it wins on a collision.
///
/// Keys are lowercase because that is how both sources identify a coin:
/// CoinGecko returns `eth`, and the WebSocket strips `USDT` from `ETHUSDT`.
final coinPricesProvider = Provider<Map<String, double>>((ref) {
  final prices = <String, double>{};

  final coins = ref.watch(marketCoinsProvider).valueOrNull;
  if (coins != null) {
    for (final coin in coins) {
      if (coin.currentPrice > 0) {
        prices[coin.symbol.toLowerCase()] = coin.currentPrice;
      }
    }
  }

  // Live ticks overwrite the cache. A zero here would be a bad frame, so skip.
  ref.watch(livePricesProvider).forEach((symbol, price) {
    if (price > 0) prices[symbol.toLowerCase()] = price;
  });

  return Map.unmodifiable(prices);
});
