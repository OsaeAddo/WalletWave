import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/portfolio/domain/ethereum_token.dart';
import 'package:wallet_wave/src/features/portfolio/domain/portfolio_snapshot.dart';
import 'package:wallet_wave/src/features/portfolio/domain/portfolio_valuation.dart';
import 'package:wallet_wave/src/features/portfolio/domain/token_balance.dart';

void main() {
  final usdc = kEthereumErc20Tokens[0];
  final link = kEthereumErc20Tokens[3];

  test('prices the native balance and each token', () {
    final valuation = PortfolioValuation.fromSnapshot(
      _snapshot(
        ethWei: _eth(2),
        tokens: [_balance(usdc, '12.5', decimals: 6)],
      ),
      {'eth': 3000, 'usdc': 1},
    );

    expect(valuation.assets, hasLength(2));
    expect(valuation.assets.first.balance.token.symbol, 'ETH');
    expect(valuation.assets.first.priceUsd, 3000);
    expect(valuation.assets.first.valueUsd, 6000);
    expect(valuation.assets[1].valueUsd, 12.5);
    expect(valuation.totalUsd, 6012.5);
    expect(valuation.isComplete, isTrue);
    expect(valuation.unpricedCount, 0);
  });

  test('keeps the snapshot order: native first, then tokens', () {
    final valuation = PortfolioValuation.fromSnapshot(
      _snapshot(
        ethWei: _eth(1),
        tokens: [
          _balance(usdc, '1', decimals: 6),
          _balance(link, '10', decimals: 18),
        ],
      ),
      {'eth': 3000, 'usdc': 1, 'link': 15},
    );

    expect(
      valuation.assets.map((a) => a.balance.token.symbol).toList(),
      ['ETH', 'USDC', 'LINK'],
    );
  });

  test('total excludes unpriced assets and flags that it is partial', () {
    final valuation = PortfolioValuation.fromSnapshot(
      _snapshot(
        ethWei: _eth(1),
        tokens: [
          _balance(link, '10', decimals: 18),
          _balance(usdc, '5', decimals: 6),
        ],
      ),
      {'eth': 3000},
    );

    expect(valuation.totalUsd, 3005);
    expect(valuation.unpricedCount, 1);
    expect(valuation.unpricedAssets.single.balance.token.symbol, 'LINK');
    expect(valuation.isComplete, isFalse);
  });

  test('stablecoins fall back to one dollar when no price is known', () {
    final valuation = PortfolioValuation.fromSnapshot(
      _snapshot(
        ethWei: BigInt.zero,
        tokens: [_balance(usdc, '2.5', decimals: 6)],
      ),
      const {},
    );

    expect(valuation.assets[1].priceUsd, 1);
    expect(valuation.assets[1].valueUsd, 2.5);
    // ETH is still unpriced, so the total only covers the dollar-pegged token.
    expect(valuation.totalUsd, 2.5);
    expect(valuation.unpricedCount, 1);
  });

  test('is null when nothing can be priced', () {
    final valuation = PortfolioValuation.fromSnapshot(
      _snapshot(
        ethWei: _eth(1),
        tokens: [_balance(link, '10', decimals: 18)],
      ),
      const {},
    );

    expect(valuation.hasPrices, isFalse);
    expect(valuation.totalUsd, isNull);
    expect(valuation.unpricedCount, 2);
  });

  test('ignores zero and negative prices instead of valuing at zero', () {
    final valuation = PortfolioValuation.fromSnapshot(
      _snapshot(ethWei: _eth(1), tokens: const []),
      {'eth': 0},
    );

    expect(valuation.assets.single.isPriced, isFalse);
    expect(valuation.totalUsd, isNull);

    final negative = PortfolioValuation.fromSnapshot(
      _snapshot(ethWei: _eth(1), tokens: const []),
      {'eth': -5},
    );
    expect(negative.assets.single.isPriced, isFalse);
  });
}

BigInt _eth(int whole) => BigInt.from(whole) * BigInt.from(10).pow(18);

/// Builds a balance from a human-readable amount by shifting the decimal point.
TokenBalance _balance(EthereumToken token, String amount,
    {required int decimals}) {
  final parts = amount.split('.');
  final whole = BigInt.parse(parts.first);
  final fractionText = parts.length == 1 ? '' : parts[1];
  final padded = fractionText.padRight(decimals, '0');
  final fraction = padded.isEmpty ? BigInt.zero : BigInt.parse(padded);
  final raw = whole * BigInt.from(10).pow(decimals) + fraction;
  return TokenBalance(token: token, rawBalance: raw);
}

PortfolioSnapshot _snapshot({
  required BigInt ethWei,
  required List<TokenBalance> tokens,
}) {
  return PortfolioSnapshot(
    address: '0x000000000000000000000000000000000000dEaD',
    nativeBalance: TokenBalance(
      token: kNativeEthereumToken,
      rawBalance: ethWei,
    ),
    tokenBalances: tokens,
  );
}
