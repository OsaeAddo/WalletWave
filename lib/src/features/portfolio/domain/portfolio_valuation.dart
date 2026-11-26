import 'ethereum_token.dart';
import 'portfolio_snapshot.dart';
import 'token_balance.dart';

/// Stablecoins are treated as $1 when no market price is available.
///
/// The app works signed out and offline, and the market cache may be empty on a
/// first run. A dollar-pegged token is still worth roughly a dollar without a
/// network call, so using 1.0 is more useful than showing "unpriced". Every
/// other asset stays unpriced rather than guessing.
const kUsdPeggedSymbols = <String>{'usdc', 'usdt', 'dai'};

/// One holding with its USD price and value.
class AssetValuation {
  const AssetValuation({required this.balance, required this.priceUsd});

  final TokenBalance balance;

  /// `null` when no price is known for this token.
  final double? priceUsd;

  bool get isPriced => priceUsd != null;

  /// Amount × price, or `null` when the price is unknown.
  double? get valueUsd {
    final price = priceUsd;
    return price == null ? null : balance.amount * price;
  }
}

/// A snapshot plus prices, ready for the portfolio screen.
///
/// The total deliberately sums only the assets that have a price. [isComplete]
/// tells the UI whether that total covers everything, so it can warn instead of
/// silently under-reporting.
class PortfolioValuation {
  const PortfolioValuation({required this.address, required this.assets});

  /// The wallet these numbers belong to.
  final String address;

  /// Native ETH first, then ERC-20 holdings, mirroring [PortfolioSnapshot].
  final List<AssetValuation> assets;

  /// Joins balances with a `lowercase symbol -> USD` price map.
  factory PortfolioValuation.fromSnapshot(
    PortfolioSnapshot snapshot,
    Map<String, double> pricesBySymbol,
  ) {
    double? priceFor(EthereumToken token) {
      final symbol = token.symbol.toLowerCase();
      final market = pricesBySymbol[symbol];
      if (market != null && market > 0) return market;
      if (kUsdPeggedSymbols.contains(symbol)) return 1;
      return null;
    }

    return PortfolioValuation(
      address: snapshot.address,
      assets: [
        AssetValuation(
          balance: snapshot.nativeBalance,
          priceUsd: priceFor(snapshot.nativeBalance.token),
        ),
        for (final balance in snapshot.tokenBalances)
          AssetValuation(
            balance: balance,
            priceUsd: priceFor(balance.token),
          ),
      ],
    );
  }

  Iterable<AssetValuation> get pricedAssets => assets.where((a) => a.isPriced);

  Iterable<AssetValuation> get unpricedAssets =>
      assets.where((a) => !a.isPriced);

  int get unpricedCount => unpricedAssets.length;

  /// True when every asset has a price, so [totalUsd] is the whole portfolio.
  bool get isComplete => unpricedCount == 0;

  bool get hasPrices => pricedAssets.isNotEmpty;

  /// Sum of the priced assets, or `null` when nothing at all could be priced.
  double? get totalUsd {
    if (!hasPrices) return null;
    var total = 0.0;
    for (final asset in pricedAssets) {
      total += asset.valueUsd!;
    }
    return total;
  }
}
