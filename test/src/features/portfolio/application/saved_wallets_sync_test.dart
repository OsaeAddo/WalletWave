import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wallet_wave/src/core/database/isar_provider.dart';
import 'package:wallet_wave/src/features/auth/application/auth_providers.dart';
import 'package:wallet_wave/src/features/auth/domain/auth_user.dart';
import 'package:wallet_wave/src/features/portfolio/application/saved_wallets_provider.dart';
import 'package:wallet_wave/src/features/portfolio/data/local/saved_wallet_entity.dart';
import 'package:wallet_wave/src/features/portfolio/data/saved_wallet_repository.dart';
import 'package:wallet_wave/src/features/portfolio/data/saved_wallets_remote.dart';
import 'package:wallet_wave/src/features/portfolio/data/saved_wallets_remote_provider.dart';

/// In-memory stand-in for the Supabase table.
class _FakeRemote implements SavedWalletsRemote {
  _FakeRemote([Map<String, String>? initial]) : rows = {...?initial};

  /// address -> label
  final Map<String, String> rows;
  final List<String> removed = [];

  @override
  Future<List<RemoteSavedWallet>> fetchAll() async => [
        for (final entry in rows.entries)
          RemoteSavedWallet(address: entry.key, label: entry.value),
      ];

  @override
  Future<void> upsert({required String address, required String label}) async {
    rows[address] = label;
  }

  @override
  Future<void> remove(String address) async {
    removed.add(address);
    rows.remove(address);
  }
}

void main() {
  late Isar isar;
  late SavedWalletRepository local;
  late Directory tempDir;

  const user = AuthUser(id: 'user-1', email: 'me@example.com');
  const localAddress = '0x0000000000000000000000000000000000000001';
  const cloudAddress = '0x0000000000000000000000000000000000000002';

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync(
      'saved_wallets_sync_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    isar = await Isar.open(
      [SavedWalletEntitySchema],
      directory: tempDir.path,
    );
    local = SavedWalletRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  ProviderContainer buildContainer(
    SavedWalletsRemote remote, {
    bool signedIn = true,
  }) {
    return ProviderContainer(
      overrides: [
        isarProvider.overrideWithValue(isar),
        savedWalletsRemoteProvider.overrideWithValue(remote),
        if (signedIn)
          authStateProvider.overrideWith(
            (ref) => Stream<AuthUser?>.value(user),
          ),
      ],
    );
  }

  test('pushes local-only wallets up and pulls cloud wallets down', () async {
    await local.save(address: localAddress, label: 'Local only');
    final remote = _FakeRemote({cloudAddress: 'Cloud only'});
    final container = buildContainer(remote);
    addTearDown(container.dispose);

    final wallets = await container.read(savedWalletsProvider.future);

    // Local-only wallet reached the cloud.
    expect(remote.rows[localAddress], 'Local only');
    // Cloud-only wallet reached the device.
    expect(
      wallets.map((wallet) => wallet.address),
      containsAll([localAddress, cloudAddress]),
    );
  });

  test('the cloud label wins when both sides have the same wallet', () async {
    await local.save(address: localAddress, label: 'Mine');
    final remote = _FakeRemote({localAddress: 'From the laptop'});
    final container = buildContainer(remote);
    addTearDown(container.dispose);

    final wallets = await container.read(savedWalletsProvider.future);

    expect(wallets, hasLength(1));
    expect(wallets.single.label, 'From the laptop');
  });

  test('saving and removing while signed in mirrors to the cloud', () async {
    final remote = _FakeRemote();
    final container = buildContainer(remote);
    addTearDown(container.dispose);

    await container.read(savedWalletsProvider.future);
    final notifier = container.read(savedWalletsProvider.notifier);

    await notifier.save(localAddress, label: 'Desk');
    expect(remote.rows[localAddress], 'Desk');

    final saved = container.read(savedWalletsProvider).value!.single;
    await notifier.remove(saved);

    expect(remote.rows, isEmpty);
    expect(remote.removed, [localAddress]);
  });

  test('signed out never touches the cloud', () async {
    final remote = _FakeRemote({cloudAddress: 'Cloud only'});
    final container = buildContainer(remote, signedIn: false);
    addTearDown(container.dispose);

    await container.read(savedWalletsProvider.future);
    await container
        .read(savedWalletsProvider.notifier)
        .save(localAddress, label: 'Local only');

    // No merge, and no mirrored write.
    expect(remote.rows, {cloudAddress: 'Cloud only'});
  });

  test('a failing cloud does not hide the local wallets', () async {
    await local.save(address: localAddress, label: 'Still here');
    final container = buildContainer(_BrokenRemote());
    addTearDown(container.dispose);

    final wallets = await container.read(savedWalletsProvider.future);

    expect(wallets.single.label, 'Still here');
  });
}

class _BrokenRemote implements SavedWalletsRemote {
  @override
  Future<List<RemoteSavedWallet>> fetchAll() async {
    throw Exception('network down');
  }

  @override
  Future<void> upsert({required String address, required String label}) async {
    throw Exception('network down');
  }

  @override
  Future<void> remove(String address) async {
    throw Exception('network down');
  }
}
