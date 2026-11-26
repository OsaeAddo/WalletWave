import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wallet_wave/src/features/portfolio/data/local/saved_wallet_entity.dart';
import 'package:wallet_wave/src/features/portfolio/data/saved_wallet_repository.dart';

void main() {
  late Isar isar;
  late SavedWalletRepository repository;
  late Directory tempDir;

  setUpAll(() async {
    // Isar's native core is not available in a plain Dart test process.
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync(
      'saved_wallet_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    isar = await Isar.open(
      [SavedWalletEntitySchema],
      directory: tempDir.path,
    );
    repository = SavedWalletRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('starts empty', () async {
    expect(await repository.getAll(), isEmpty);
  });

  test('saves a wallet and returns it as a domain model', () async {
    await repository.save(
      address: '0x000000000000000000000000000000000000dEaD',
      label: 'Cold storage',
    );

    final wallets = await repository.getAll();

    expect(wallets, hasLength(1));
    expect(wallets.single.label, 'Cold storage');
    // Addresses are normalized, so lookups are case-insensitive.
    expect(
      wallets.single.address,
      '0x000000000000000000000000000000000000dead',
    );
  });

  test('does not duplicate the same address in a different casing', () async {
    await repository.save(
      address: '0x000000000000000000000000000000000000dEaD',
      label: 'First',
    );
    await repository.save(
      address: '0x000000000000000000000000000000000000DEAD',
      label: 'Updated',
    );

    final wallets = await repository.getAll();

    expect(wallets, hasLength(1));
    expect(wallets.single.label, 'Updated');
  });

  test('remove deletes only the requested wallet', () async {
    await repository.save(
      address: '0x0000000000000000000000000000000000000001',
      label: 'One',
    );
    await repository.save(
      address: '0x0000000000000000000000000000000000000002',
      label: 'Two',
    );

    final wallets = await repository.getAll();
    final toRemove = wallets.firstWhere((wallet) => wallet.label == 'One').id;

    await repository.remove(toRemove);

    final remaining = await repository.getAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.label, 'Two');
  });
}
