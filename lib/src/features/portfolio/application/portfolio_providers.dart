import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet/wallet.dart';
import '../data/evm_provider.dart';
import '../domain/wallet_balance.dart';

final selectedAddressProvider = StateProvider<String>((ref) => '');

final walletBalanceProvider = FutureProvider<WalletBalance?>((ref) async {
  final addressHex = ref.watch(selectedAddressProvider).trim();
  if (addressHex.isEmpty) return null;

  // Validate Ethereum hex address before making RPC call
  try {
    EthereumAddress.fromHex(addressHex);
  } catch (_) {
    throw Exception('Invalid Ethereum address format');
  }

  final evmService = ref.watch(evmClientServiceProvider);
  final rawAmount = await evmService.getNativeBalance(addressHex);

  return WalletBalance(
    address: addressHex,
    nativeBalanceEther: rawAmount.getValueInUnit(EtherUnit.ether),
    symbol: 'ETH',
  );
});
