import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/database/isar_provider.dart';
import '../domain/saved_wallet.dart';
import 'local/saved_wallet_entity.dart';

final savedWalletRepositoryProvider = Provider<SavedWalletRepository>((ref) {
  return SavedWalletRepository(ref.watch(isarProvider));
});

/// Persists saved wallets in Isar.
///
/// Addresses are stored lowercase. Ethereum addresses are case-insensitive
/// (checksum casing is only a display detail), so lowercasing before the unique
/// index lookup is what makes "same wallet, different casing" collapse into one
/// row.
class SavedWalletRepository {
  SavedWalletRepository(this._isar);

  final Isar _isar;

  Future<List<SavedWallet>> getAll() async {
    final rows =
        await _isar.savedWalletEntitys.where().sortByCreatedAtDesc().findAll();
    return rows.map(_toDomain).toList(growable: false);
  }

  /// Inserts a new wallet or updates the label of an existing one.
  Future<void> save({
    required String address,
    required String label,
  }) async {
    final normalized = _normalize(address);
    final existing = await _isar.savedWalletEntitys
        .filter()
        .addressEqualTo(normalized)
        .findFirst();

    final entity = SavedWalletEntity()
      ..id = existing?.id ?? Isar.autoIncrement
      ..address = normalized
      ..label = label
      // Keep the original creation time when only the label changes.
      ..createdAt = existing?.createdAt ?? DateTime.now();

    await _isar.writeTxn(() => _isar.savedWalletEntitys.put(entity));
  }

  Future<void> remove(int id) async {
    await _isar.writeTxn(() => _isar.savedWalletEntitys.delete(id));
  }

  static String _normalize(String address) => address.trim().toLowerCase();

  static SavedWallet _toDomain(SavedWalletEntity entity) => SavedWallet(
        id: entity.id,
        address: entity.address,
        label: entity.label,
      );
}
