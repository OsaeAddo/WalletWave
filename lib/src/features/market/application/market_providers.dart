import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/market_repository.dart';
import '../domain/market_coin.dart';

/// Cache-first market data.
///
/// [build] paints cached coins immediately and refreshes once in the
/// background. It never calls `invalidateSelf`, so there is no refresh loop.
final marketCoinsProvider =
    AsyncNotifierProvider<MarketCoinsNotifier, List<MarketCoin>>(
  MarketCoinsNotifier.new,
);

class MarketCoinsNotifier extends AsyncNotifier<List<MarketCoin>> {
  bool _disposed = false;

  @override
  Future<List<MarketCoin>> build() async {
    ref.onDispose(() => _disposed = true);

    final repository = ref.watch(marketRepositoryProvider);
    final cached = await repository.getCachedMarketCoins();

    if (cached.isEmpty) {
      return repository.fetchAndCacheMarketCoins();
    }

    // Show the cache now, then replace it when the network responds.
    _refreshInBackground(repository);
    return cached;
  }

  /// Manual refresh used by the app bar button. Keeps the previous data
  /// visible while the request is in flight.
  Future<void> refresh() async {
    state = const AsyncLoading<List<MarketCoin>>().copyWithPrevious(state);
    try {
      final fresh =
          await ref.read(marketRepositoryProvider).fetchAndCacheMarketCoins();
      if (!_disposed) state = AsyncData(fresh);
    } catch (error, stackTrace) {
      if (!_disposed) {
        state = AsyncError<List<MarketCoin>>(error, stackTrace)
            .copyWithPrevious(state);
      }
    }
  }

  void _refreshInBackground(MarketRepository repository) {
    Future(() async {
      try {
        final fresh = await repository.fetchAndCacheMarketCoins();
        if (!_disposed) state = AsyncData(fresh);
      } catch (_) {
        // Cache is still valid; a manual refresh can surface the error.
      }
    });
  }
}

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
