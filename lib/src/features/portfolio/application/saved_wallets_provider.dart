import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wallet/wallet.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_user.dart';
import '../data/saved_wallet_repository.dart';
import '../data/saved_wallets_remote.dart';
import '../data/saved_wallets_remote_provider.dart';
import '../data/wallet_backup_service.dart';
import '../domain/saved_wallet.dart';
import 'portfolio_providers.dart';
import 'saved_wallets_realtime.dart';
import 'wallet_backup_provider.dart';

final savedWalletsProvider =
    AsyncNotifierProvider<SavedWalletsNotifier, List<SavedWallet>>(
  SavedWalletsNotifier.new,
);

/// Local-first list of the user's wallets.
///
/// Isar is always the source of truth for the UI, so the list appears instantly
/// and works with no network. When a user is signed in, the cloud is merged in
/// on build and writes are mirrored to it on a best-effort basis.
class SavedWalletsNotifier extends AsyncNotifier<List<SavedWallet>> {
  bool _pulling = false;
  int? _lastSeenEventId;

  @override
  Future<List<SavedWallet>> build() async {
    final repository = ref.watch(savedWalletRepositoryProvider);

    // Wait for the first auth event rather than reading the current value:
    // the stream replays a restored session immediately, and awaiting it means
    // the list is already merged when it first appears.
    AuthUser? user;
    try {
      user = await ref.watch(authStateProvider.future).timeout(
            // A broken auth backend must not block the local list forever.
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
    } catch (_) {
      // Auth is optional; an auth failure must not hide local wallets.
      user = null;
    }

    if (user != null) {
      await _mergeCloudIntoLocal(repository);

      // Another device changed the cloud list: pull it into Isar without
      // pushing local rows back up, which would loop.
      ref.listen(savedWalletFeedProvider, (previous, next) {
        final latest = next.valueOrNull?.latest;
        if (latest == null || latest.id == _lastSeenEventId) return;
        _lastSeenEventId = latest.id;
        unawaited(_pullCloudIntoLocal());
      });
    }

    return repository.getAll();
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
    final finalLabel = cleanLabel.isEmpty ? shortAddress(trimmed) : cleanLabel;

    await repository.save(address: trimmed, label: finalLabel);

    // Local save already succeeded; a cloud failure must not undo it.
    await _mirror(
      (remote) => remote.upsert(
        address: trimmed.toLowerCase(),
        label: finalLabel,
      ),
    );

    // Re-read so the UI sees the exact persisted rows (then sorted).
    state = AsyncData(await repository.getAll());
    ref.read(selectedAddressProvider.notifier).state = trimmed;
  }

  Future<void> remove(SavedWallet wallet) async {
    final repository = ref.read(savedWalletRepositoryProvider);
    await repository.remove(wallet.id);

    await _mirror((remote) => remote.remove(wallet.address));

    state = AsyncData(await repository.getAll());
  }

  /// Pushes wallets that exist only on this machine, then pulls the cloud list
  /// into the local cache.
  ///
  /// Labels are not conflict-merged: when the same address exists in both
  /// places the cloud label wins. That is simple and predictable, and labels
  /// are cosmetic. Addresses are the data that matters, and they are unique
  /// per user in the database.
  Future<void> _mergeCloudIntoLocal(SavedWalletRepository repository) async {
    final remote = ref.read(savedWalletsRemoteProvider);
    if (remote == null) return;

    try {
      final cloudWallets = await remote.fetchAll();
      final cloudAddresses = {
        for (final wallet in cloudWallets) wallet.address,
      };

      for (final local in await repository.getAll()) {
        if (!cloudAddresses.contains(local.address)) {
          await remote.upsert(address: local.address, label: local.label);
        }
      }

      for (final remoteWallet in cloudWallets) {
        await repository.save(
          address: remoteWallet.address,
          label: remoteWallet.label,
        );
      }
    } catch (_) {
      // Cloud sync is optional. Keep the local list usable when it fails.
    }
  }

  /// Runs a cloud write and ignores failures.
  ///
  /// Offline-first means the local write is the real one. Failing the whole
  /// action because the network is down would be a regression.
  Future<void> _mirror(
    Future<void> Function(SavedWalletsRemote remote) action,
  ) async {
    // Signed out: there is no account to write to, and the anonymous database
    // role has no permission to touch this table.
    if (ref.read(authStateProvider).valueOrNull == null) return;

    final remote = ref.read(savedWalletsRemoteProvider);
    if (remote == null) return;

    try {
      await action(remote);
    } catch (_) {
      // Intentionally ignored; see doc comment.
    }
  }

  /// Reads the cloud list into Isar without writing anything back.
  ///
  /// Used for realtime notifications. Pushing local-only rows here would make
  /// two devices echo each other forever.
  Future<void> _pullCloudIntoLocal() async {
    if (_pulling) return;
    final remote = ref.read(savedWalletsRemoteProvider);
    if (remote == null) return;

    _pulling = true;
    try {
      final cloud = await remote.fetchAll();
      final repository = ref.read(savedWalletRepositoryProvider);
      for (final wallet in cloud) {
        await repository.save(address: wallet.address, label: wallet.label);
      }
      state = AsyncData(await repository.getAll());
    } catch (_) {
      // A live signal is best-effort; the next event retries.
    } finally {
      _pulling = false;
    }
  }

  /// Uploads every saved wallet to the user's private bucket.
  ///
  /// Returns how many wallets were included. Throws [WalletBackupException]
  /// with a message safe to show the user.
  Future<int> backupToCloud() async {
    final service = ref.read(walletBackupServiceProvider);
    if (service == null) {
      throw const WalletBackupException(
        'Cloud backup is not configured in this build.',
      );
    }

    final wallets = await ref.read(savedWalletRepositoryProvider).getAll();
    await service.backup(wallets);
    return wallets.length;
  }

  /// Merges the cloud backup into this device and the cloud list.
  ///
  /// Restore never deletes: newer wallets that are not in the backup stay.
  /// Invalid addresses in the file are skipped, so a corrupted export cannot
  /// poison the portfolio.
  Future<int> restoreFromCloud() async {
    final service = ref.read(walletBackupServiceProvider);
    if (service == null) {
      throw const WalletBackupException(
        'Cloud backup is not configured in this build.',
      );
    }

    final entries = await service.download();
    if (entries == null) {
      throw const WalletBackupException(
        'No cloud backup exists for this account yet.',
      );
    }

    final repository = ref.read(savedWalletRepositoryProvider);
    var restored = 0;
    for (final entry in entries) {
      final address = entry.address.trim();
      try {
        EthereumAddress.fromHex(address);
      } catch (_) {
        continue;
      }

      await repository.save(address: address, label: entry.label);
      await _mirror(
        (remote) => remote.upsert(
          address: address.toLowerCase(),
          label: entry.label,
        ),
      );
      restored += 1;
    }

    state = AsyncData(await repository.getAll());
    return restored;
  }
}

/// `0x1234…abcd` — compact enough for a chip label.
String shortAddress(String address) {
  if (address.length <= 12) return address;
  return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
}
