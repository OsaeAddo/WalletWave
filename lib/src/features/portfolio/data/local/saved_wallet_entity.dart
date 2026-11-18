import 'package:isar_community/isar.dart';

part 'saved_wallet_entity.g.dart';

/// Isar row for a saved wallet.
///
/// `address` carries a unique index, which is what prevents the same wallet
/// being saved twice. The repository normalizes it to lowercase before writing.
@collection
class SavedWalletEntity {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String address;

  late String label;

  /// Sort key for "most recently added first".
  late DateTime createdAt;
}
