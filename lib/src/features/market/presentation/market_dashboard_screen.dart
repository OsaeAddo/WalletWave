import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/market_repository.dart';
import '../domain/market_coin.dart';
import '../data/market_price_ws_provider.dart';

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

class MarketDashboardScreen extends ConsumerWidget {
  const MarketDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredMarketData = ref.watch(filteredMarketCoinsProvider);

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
      body: Column(
        children: [
          const _SearchBarWidget(),
          Expanded(
            child: filteredMarketData.when(
              data: (coins) {
                if (coins.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching coins found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: coins.length,
                  itemBuilder: (context, index) {
                    return _CoinListTile(coin: coins[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarWidget extends ConsumerStatefulWidget {
  const _SearchBarWidget();

  @override
  ConsumerState<_SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends ConsumerState<_SearchBarWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: 'Search coin or symbol (e.g., BTC, Solana)...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).state = '';
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
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
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
