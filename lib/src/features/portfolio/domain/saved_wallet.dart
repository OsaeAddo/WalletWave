/// A wallet address the user chose to keep, with a display label.
class SavedWallet {
  const SavedWallet({
    required this.id,
    required this.address,
    required this.label,
  });

  /// Isar row id, used to delete the entry.
  final int id;

  /// Lowercase hex address, so duplicates compare reliably.
  final String address;
  final String label;
}
