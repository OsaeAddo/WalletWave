import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/market_repository.dart';
import '../domain/market_coin.dart';
import '../data/market_price_ws_provider.dart';

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
            // Use the extracted widget to isolate rebuilds
            return _CoinListTile(coin: coins[index]);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child:
              Text(error.toString(), style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}

// Extracted widget to handle real-time micro-updates efficiently
class _CoinListTile extends ConsumerWidget {
  final MarketCoin coin;

  const _CoinListTile({required this.coin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .select() ensures this specific row ONLY rebuilds when its specific ticker changes
    final livePrice = ref.watch(
      livePricesProvider.select((prices) => prices[coin.symbol.toLowerCase()]),
    );

    // Fall back to the cached Isar database price if the WebSocket hasn't ticked yet
    final displayPrice = livePrice ?? coin.currentPrice;
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
            '\$${displayPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            '${isPositive ? '+' : ''}${coin.priceChange24h?.toStringAsFixed(2)}%',
            style:
                TextStyle(color: isPositive ? Colors.green : Colors.redAccent),
          ),
        ],
      ),
    );
  }
}
