import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:wallet_wave/src/core/database/isar_provider.dart';
import 'package:wallet_wave/src/features/portfolio/application/portfolio_providers.dart';
import 'package:wallet_wave/src/features/portfolio/application/saved_wallets_provider.dart';
import 'package:wallet_wave/src/features/portfolio/data/local/saved_wallet_entity.dart';

void main() {
  late Isar isar;
  late ProviderContainer container;
  late Directory tempDir;

  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync(
      'saved_wallets_notifier_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    isar = await Isar.open(
      [SavedWalletEntitySchema],
      directory: tempDir.path,
    );
    container = ProviderContainer(
      overrides: [isarProvider.overrideWithValue(isar)],
    );
  });

  tearDown(() async {
    container.dispose();
    await isar.close(deleteFromDisk: true);
  });

  test('save persists the wallet and selects its address', () async {
    await container
        .read(savedWalletsProvider.notifier)
        .save('0x000000000000000000000000000000000000dEaD');

    final wallets = container.read(savedWalletsProvider).value;

    expect(wallets, hasLength(1));
    // No label supplied, so the shortened address is used.
    expect(wallets!.single.label, '0x0000…dEaD');
    expect(
      container.read(selectedAddressProvider),
      '0x000000000000000000000000000000000000dEaD',
    );
  });

  test('save rejects an empty address', () async {
    await expectLater(
      container.read(savedWalletsProvider.notifier).save('  '),
      throwsA(
        predicate((e) => e.toString().contains('Enter an address')),
      ),
    );
    expect(await container.read(savedWalletsProvider.future), isEmpty);
  });

  test('save rejects a malformed address', () async {
    await expectLater(
      container.read(savedWalletsProvider.notifier).save('not-an-address'),
      throwsA(
        predicate((e) => e.toString().contains('Invalid Ethereum address')),
      ),
    );
  });

  test('remove keeps the remaining wallets', () async {
    final notifier = container.read(savedWalletsProvider.notifier);
    await notifier.save('0x0000000000000000000000000000000000000001');
    await notifier.save('0x0000000000000000000000000000000000000002');

    final first = container
        .read(savedWalletsProvider)
        .value!
        .firstWhere((w) => w.label.endsWith('0001'));
    await notifier.remove(first);

    expect(container.read(savedWalletsProvider).value, hasLength(1));
  });
}
