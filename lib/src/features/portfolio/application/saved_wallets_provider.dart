import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet/wallet.dart';

import '../data/saved_wallet_repository.dart';
import '../domain/saved_wallet.dart';
import 'portfolio_providers.dart';

final savedWalletsProvider =
    AsyncNotifierProvider<SavedWalletsNotifier, List<SavedWallet>>(
  SavedWalletsNotifier.new,
);

class SavedWalletsNotifier extends AsyncNotifier<List<SavedWallet>> {
  @override
  Future<List<SavedWallet>> build() {
    return ref.watch(savedWalletRepositoryProvider).getAll();
  }

  /// Validates the address, persists it, then loads it into the portfolio.
  ///
  /// Saving and loading in one step is intentional: the reason a user saves a
  /// wallet is to come back to it later, and leaving the screen showing an
  /// unrelated address would be surprising.
  Future<void> save(String address, {String? label}) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      throw Exception('Enter an address before saving');
    }

    try {
      EthereumAddress.fromHex(trimmed);
    } catch (_) {
      throw Exception('Invalid Ethereum address format');
    }

    final repository = ref.read(savedWalletRepositoryProvider);
    final cleanLabel = (label ?? '').trim();
    await repository.save(
      address: trimmed,
      label: cleanLabel.isEmpty ? shortAddress(trimmed) : cleanLabel,
    );

    // Re-read so the UI sees the exact persisted rows (then sorted).
    state = AsyncData(await repository.getAll());
    ref.read(selectedAddressProvider.notifier).state = trimmed;
  }

  Future<void> remove(int id) async {
    final repository = ref.read(savedWalletRepositoryProvider);
    await repository.remove(id);
    state = AsyncData(await repository.getAll());
  }
}

/// `0x1234…abcd` — compact enough for a chip label.
String shortAddress(String address) {
  if (address.length <= 12) return address;
  return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
}
