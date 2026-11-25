import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../market/application/coin_prices_provider.dart';
import '../domain/portfolio_valuation.dart';
import 'portfolio_providers.dart';

/// The loaded portfolio joined with current prices.
///
/// This is a derived provider on purpose: balances change only when RPC calls
/// finish, but prices tick every second. Watching both here lets the UI repaint
/// the valuation without re-fetching balances.
///
/// `null` means no address is loaded, the same contract as [portfolioProvider].
final portfolioValuationProvider =
    Provider<AsyncValue<PortfolioValuation?>>((ref) {
  final prices = ref.watch(coinPricesProvider);
  return ref.watch(portfolioProvider).whenData(
        (snapshot) => snapshot == null
            ? null
            : PortfolioValuation.fromSnapshot(snapshot, prices),
      );
});
