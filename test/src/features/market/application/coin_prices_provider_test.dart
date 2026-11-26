import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/market/application/coin_prices_provider.dart';
import 'package:wallet_wave/src/features/market/application/market_providers.dart';
import 'package:wallet_wave/src/features/market/data/market_price_ws_provider.dart';
import 'package:wallet_wave/src/features/market/domain/market_coin.dart';

void main() {
  test('falls back to cached market prices when there are no live ticks',
      () async {
    final container = _container(
      coins: [
        _coin(symbol: 'eth', price: 3100),
        _coin(symbol: 'link', price: 15.25),
      ],
      live: const {},
    );
    addTearDown(container.dispose);

    await container.read(marketCoinsProvider.future);

    expect(container.read(coinPricesProvider), {
      'eth': 3100.0,
      'link': 15.25,
    });
  });

  test('a live tick wins over the cached price', () async {
    final container = _container(
      coins: [_coin(symbol: 'eth', price: 3100)],
      live: const {'eth': 3150.75},
    );
    addTearDown(container.dispose);

    await container.read(marketCoinsProvider.future);

    expect(container.read(coinPricesProvider)['eth'], 3150.75);
  });

  test('ignores non-positive prices from either source', () async {
    final container = _container(
      coins: [_coin(symbol: 'eth', price: 0)],
      live: const {'btc': 0, 'sol': 150},
    );
    addTearDown(container.dispose);

    await container.read(marketCoinsProvider.future);

    expect(container.read(coinPricesProvider), {'sol': 150.0});
  });

  test('is an immutable snapshot', () async {
    final container = _container(
      coins: [_coin(symbol: 'eth', price: 3100)],
      live: const {},
    );
    addTearDown(container.dispose);

    await container.read(marketCoinsProvider.future);

    expect(
      () => container.read(coinPricesProvider)['eth'] = 1,
      throwsUnsupportedError,
    );
  });
}

ProviderContainer _container({
  required List<MarketCoin> coins,
  required Map<String, double> live,
}) {
  return ProviderContainer(
    overrides: [
      marketCoinsProvider.overrideWith(() => _StaticCoins(coins)),
      livePricesProvider.overrideWith(() => _StaticLivePrices(live)),
    ],
  );
}

MarketCoin _coin({required String symbol, required double price}) {
  return MarketCoin(
    id: symbol,
    symbol: symbol,
    name: symbol.toUpperCase(),
    currentPrice: price,
    imageUrl: 'https://example.invalid/$symbol.png',
  );
}

class _StaticCoins extends MarketCoinsNotifier {
  _StaticCoins(this.coins);

  final List<MarketCoin> coins;

  @override
  Future<List<MarketCoin>> build() async => coins;
}

class _StaticLivePrices extends LivePricesNotifier {
  _StaticLivePrices(this.prices);

  final Map<String, double> prices;

  @override
  Map<String, double> build() => prices;
}
