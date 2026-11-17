import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/market_repository.dart';
import '../domain/market_coin.dart';

// Provides the raw market coins list (Cache-then-Network)
final marketCoinsProvider = FutureProvider<List<MarketCoin>>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);
  final cached = await repository.getCachedMarketCoins();
  if (cached.isNotEmpty) {
    repository.fetchAndCacheMarketCoins().then((fresh) {
      ref.invalidateSelf();
    }).catchError((_) {});
    return cached;
  }
  return repository.fetchAndCacheMarketCoins();
});

// Holds the active search query string
final searchQueryProvider = StateProvider<String>((ref) => '');

// Derives a filtered subset of market coins based on name or symbol match
final filteredMarketCoinsProvider =
    Provider<AsyncValue<List<MarketCoin>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final marketData = ref.watch(marketCoinsProvider);

  return marketData.whenData((coins) {
    if (query.isEmpty) return coins;
    return coins.where((coin) {
      return coin.name.toLowerCase().contains(query) ||
          coin.symbol.toLowerCase().contains(query);
    }).toList();
  });
});
