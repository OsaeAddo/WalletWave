import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/portfolio/application/portfolio_valuation_provider.dart';
import 'package:wallet_wave/src/features/portfolio/application/saved_wallets_provider.dart';
import 'package:wallet_wave/src/features/portfolio/domain/ethereum_token.dart';
import 'package:wallet_wave/src/features/portfolio/domain/portfolio_snapshot.dart';
import 'package:wallet_wave/src/features/portfolio/domain/portfolio_valuation.dart';
import 'package:wallet_wave/src/features/portfolio/domain/saved_wallet.dart';
import 'package:wallet_wave/src/features/portfolio/domain/token_balance.dart';
import 'package:wallet_wave/src/features/portfolio/presentation/portfolio_screen.dart';

void main() {
  testWidgets('shows the total, the native value and priced tokens', (
    tester,
  ) async {
    final valuation = _valuation(
      ethWei: _eth(2),
      tokens: [_balance(kEthereumErc20Tokens[0], '12.5', decimals: 6)],
      prices: const {'eth': 3000, 'usdc': 1},
    );

    await _pump(tester, valuation);

    expect(find.text('Portfolio value'), findsOneWidget);
    expect(find.text('\$6,012.50'), findsOneWidget);
    expect(find.text('2 ETH'), findsOneWidget);
    expect(find.text('\$6,000.00'), findsOneWidget);
    expect(find.text('USDC'), findsOneWidget);
    expect(find.text('\$12.50'), findsOneWidget);
    expect(find.textContaining('Excludes'), findsNothing);
  });

  testWidgets('flags assets that could not be priced and still totals the rest',
      (
    tester,
  ) async {
    final valuation = _valuation(
      ethWei: _eth(1),
      tokens: [
        _balance(kEthereumErc20Tokens[0], '5', decimals: 6),
        _balance(kEthereumErc20Tokens[3], '10', decimals: 18),
      ],
      prices: const {'eth': 3000},
    );

    await _pump(tester, valuation);

    // Total = 1 ETH + 5 USDC at the $1 peg; LINK has no price.
    expect(find.text('\$3,005.00'), findsOneWidget);
    expect(find.text('\$3,000.00'), findsOneWidget);
    expect(find.text('Excludes 1 asset with no market price.'), findsOneWidget);
    expect(find.text('no price'), findsOneWidget);
  });

  testWidgets('shows a dash when nothing has a price', (tester) async {
    final valuation = _valuation(
      ethWei: _eth(1),
      tokens: const [],
      prices: const {},
    );

    await _pump(tester, valuation);

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Excludes 1 asset with no market price.'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, PortfolioValuation valuation) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioValuationProvider.overrideWithValue(AsyncData(valuation)),
        savedWalletsProvider.overrideWith(_EmptySavedWallets.new),
      ],
      child: const MaterialApp(home: PortfolioScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

PortfolioValuation _valuation({
  required BigInt ethWei,
  required List<TokenBalance> tokens,
  required Map<String, double> prices,
}) {
  final snapshot = PortfolioSnapshot(
    address: '0x000000000000000000000000000000000000dEaD',
    nativeBalance: TokenBalance(
      token: kNativeEthereumToken,
      rawBalance: ethWei,
    ),
    tokenBalances: tokens,
  );
  return PortfolioValuation.fromSnapshot(snapshot, prices);
}

BigInt _eth(int whole) => BigInt.from(whole) * BigInt.from(10).pow(18);

TokenBalance _balance(
  EthereumToken token,
  String amount, {
  required int decimals,
}) {
  final parts = amount.split('.');
  final whole = BigInt.parse(parts.first);
  final fractionText = parts.length == 1 ? '' : parts[1];
  final fraction = fractionText.isEmpty
      ? BigInt.zero
      : BigInt.parse(fractionText.padRight(decimals, '0'));
  return TokenBalance(
    token: token,
    rawBalance: whole * BigInt.from(10).pow(decimals) + fraction,
  );
}

class _EmptySavedWallets extends SavedWalletsNotifier {
  @override
  Future<List<SavedWallet>> build() async => const [];
}
