import 'package:flutter/material.dart';
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

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(walletBalanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVM Portfolio'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'EVM Wallet Address',
                hintText: '0x...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () {
                    ref.read(selectedAddressProvider.notifier).state =
                        _addressController.text;
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            balanceAsync.when(
              data: (wallet) {
                if (wallet == null) {
                  return const Center(
                    child:
                        Text('Enter an EVM address to query on-chain balance.'),
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Native Balance',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${wallet.nativeBalanceEther.toStringAsFixed(4)} ${wallet.symbol}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  err.toString().replaceAll('Exception: ', ''),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
