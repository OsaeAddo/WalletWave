import 'ethereum_token.dart';
import 'token_balance.dart';

/// Everything the portfolio screen renders for one address.
class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.address,
    required this.nativeBalance,
    required this.tokenBalances,
  });

  final String address;
  final TokenBalance nativeBalance;

  /// ERC-20 holdings with a non-zero balance, in [kEthereumErc20Tokens] order.
  final List<TokenBalance> tokenBalances;
}
