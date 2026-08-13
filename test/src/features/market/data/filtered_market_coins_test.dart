import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wallet_wave/src/features/market/domain/market_coin.dart';
import 'package:wallet_wave/src/features/market/presentation/market_dashboard_screen.dart';

void main() {
  // 1. Arrange: Define static mock data to feed the provider
  final mockCoins = [
    const MarketCoin(
      id: 'bitcoin',
      symbol: 'btc',
      name: 'Bitcoin',
      currentPrice: 65000.0,
      priceChange24h: 2.5,
      imageUrl: 'https://example.com/btc.png',
    ),
    const MarketCoin(
      id: 'ethereum',
      symbol: 'eth',
      name: 'Ethereum',
      currentPrice: 3500.0,
      priceChange24h: -1.2,
      imageUrl: 'https://example.com/eth.png',
    ),
    const MarketCoin(
      id: 'solana',
      symbol: 'sol',
      name: 'Solana',
      currentPrice: 150.0,
      priceChange24h: 5.0,
      imageUrl: 'https://example.com/sol.png',
    ),
  ];

  /// Helper method to initialize a Riverpod container with mocked dependencies.
  /// This ensures every test starts with a fresh, unpolluted state.
  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer(
      overrides: [
        // Override the FutureProvider to instantly return our static mock data
        // instead of executing the Isar/Dio repository logic.
        marketCoinsProvider.overrideWith((ref) => mockCoins),
      ],
    );

    // Automatically dispose the container after the test finishes to prevent memory leaks
    addTearDown(container.dispose);

    return container;
  }

  group('Filtered Search Provider Tests', () {
    test('returns the full list of coins when the search query is empty',
        () async {
      final container = makeProviderContainer();

      // Wait for the mocked FutureProvider to resolve from loading state to data state
      await container.read(marketCoinsProvider.future);

      // Read the synchronous derived state
      final filteredData = container.read(filteredMarketCoinsProvider);

      expect(filteredData, isA<AsyncData<List<MarketCoin>>>());
      expect(filteredData.value!.length, 3);
    });

    test('filters correctly by coin name (case-insensitive)', () async {
      final container = makeProviderContainer();

      // Update the search query state to trigger the filter logic
      container.read(searchQueryProvider.notifier).state = 'ethe';

      await container.read(marketCoinsProvider.future);
      final filteredData = container.read(filteredMarketCoinsProvider);

      expect(filteredData.value!.length, 1);
      expect(filteredData.value!.first.name, 'Ethereum');
    });

    test('filters correctly by coin symbol (case-insensitive)', () async {
      final container = makeProviderContainer();

      // Update the search query state to test symbol matching
      container.read(searchQueryProvider.notifier).state = 'BTC';

      await container.read(marketCoinsProvider.future);
      final filteredData = container.read(filteredMarketCoinsProvider);

      expect(filteredData.value!.length, 1);
      expect(filteredData.value!.first.symbol, 'btc');
    });

    test('returns an empty list when no matches are found', () async {
      final container = makeProviderContainer();

      // Input a query that doesn't exist in our mock data
      container.read(searchQueryProvider.notifier).state = 'doge';

      await container.read(marketCoinsProvider.future);
      final filteredData = container.read(filteredMarketCoinsProvider);

      expect(filteredData.value, isEmpty);
    });
  });
}
