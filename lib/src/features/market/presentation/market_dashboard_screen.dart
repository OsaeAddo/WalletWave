import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/market_repository.dart';
import '../domain/market_coin.dart';

final marketCoinsProvider = FutureProvider<List<MarketCoin>>((ref) async {
  final repository = ref.watch(marketRepositoryProvider);

  // 1. Return cache immediately if available
  final cached = await repository.getCachedMarketCoins();
  if (cached.isNotEmpty) {
    // Asynchronously update in the background
    repository.fetchAndCacheMarketCoins().then((fresh) {
      ref.invalidateSelf(); // Refresh provider when new network data lands
    }).catchError((_) {});
    return cached;
  }

  // 2. Fall back to network fetch on first launch
  return repository.fetchAndCacheMarketCoins();
});

class MarketDashboardScreen extends ConsumerWidget {
  const MarketDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketData = ref.watch(marketCoinsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Markets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final repo = ref.read(marketRepositoryProvider);
              await repo.fetchAndCacheMarketCoins();
              ref.invalidate(marketCoinsProvider);
            },
          )
        ],
      ),
      body: marketData.when(
        data: (coins) => ListView.builder(
          itemCount: coins.length,
          itemBuilder: (context, index) {
            final coin = coins[index];
            final isPositive = (coin.priceChange24h ?? 0) >= 0;

            return ListTile(
              leading: Image.network(coin.imageUrl, width: 40, height: 40),
              title: Text(coin.name),
              subtitle: Text(coin.symbol.toUpperCase()),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${coin.currentPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${coin.priceChange24h?.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.redAccent,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
