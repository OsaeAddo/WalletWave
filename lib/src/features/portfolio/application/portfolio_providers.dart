import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet/wallet.dart';

import '../data/evm_provider.dart';
import '../domain/ethereum_token.dart';
import '../domain/portfolio_snapshot.dart';
import '../domain/token_balance.dart';

/// The address currently displayed in the portfolio screen.
final selectedAddressProvider = StateProvider<String>((ref) => '');

/// Loads the native balance plus every tracked ERC-20 balance for the selected
/// address.
///
/// `null` means "no address entered yet" — a valid, non-error state. Failures
/// (bad hex, RPC down) surface as [AsyncError] so the UI can show a message.
final portfolioProvider =
    AsyncNotifierProvider<PortfolioNotifier, PortfolioSnapshot?>(
  PortfolioNotifier.new,
);

class PortfolioNotifier extends AsyncNotifier<PortfolioSnapshot?> {
  @override
  Future<PortfolioSnapshot?> build() async {
    final addressHex = ref.watch(selectedAddressProvider).trim();
    if (addressHex.isEmpty) return null;

    // Fail fast with a readable message before any network call.
    try {
      EthereumAddress.fromHex(addressHex);
    } catch (_) {
      throw Exception('Invalid Ethereum address format');
    }

    final service = ref.watch(evmClientServiceProvider);

    // Native and ERC-20 calls are independent, so run them concurrently.
    // Each token maps to one `eth_call`; four tokens means four requests.
    final results = await Future.wait([
      service.getNativeBalance(addressHex),
      for (final token in kEthereumErc20Tokens)
        service.getErc20Balance(
          tokenContractHex: token.contractAddress,
          walletAddressHex: addressHex,
        ),
    ]);

    final nativeRaw = results.first as EtherAmount;
    final tokenBalances = <TokenBalance>[
      for (var i = 0; i < kEthereumErc20Tokens.length; i++)
        TokenBalance(
          token: kEthereumErc20Tokens[i],
          rawBalance: results[i + 1] as BigInt,
        ),
    ].where((balance) => balance.hasBalance).toList(growable: false);

    return PortfolioSnapshot(
      address: addressHex,
      nativeBalance: TokenBalance(
        token: kNativeEthereumToken,
        rawBalance: nativeRaw.getInWei,
      ),
      tokenBalances: tokenBalances,
    );
  }

  /// Re-runs the RPC calls for the current address.
  Future<void> refresh() async {
    state = const AsyncLoading<PortfolioSnapshot?>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }
}
