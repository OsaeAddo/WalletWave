/// One saved wallet as stored in the cloud.
class RemoteSavedWallet {
  const RemoteSavedWallet({required this.address, required this.label});

  final String address;
  final String label;
}

/// The cloud copy of saved wallets.
///
/// This is an interface for the same reason [AuthRepository] is: tests can
/// supply a fake without a network, and the Supabase version can be replaced
/// by a FastAPI version later.
abstract interface class SavedWalletsRemote {
  Future<List<RemoteSavedWallet>> fetchAll();

  /// Insert or update one row. `address` must already be lowercase.
  Future<void> upsert({required String address, required String label});

  Future<void> remove(String address);
}
