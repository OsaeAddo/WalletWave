import 'package:supabase_flutter/supabase_flutter.dart';

import 'saved_wallets_remote.dart';

/// [SavedWalletsRemote] backed by a Postgres table through Supabase.
///
/// No user id is sent: the table defaults `user_id` to `auth.uid()`, and Row
/// Level Security scopes every read and write to the signed-in user. The SDK
/// attaches the auth token to each request automatically.
class SupabaseSavedWalletsRemote implements SavedWalletsRemote {
  SupabaseSavedWalletsRemote(this._client);

  final SupabaseClient _client;

  static const _table = 'saved_wallets';

  @override
  Future<List<RemoteSavedWallet>> fetchAll() async {
    final rows = await _client
        .from(_table)
        .select('address, label')
        .order('created_at', ascending: false);

    return [
      for (final row in rows)
        RemoteSavedWallet(
          address: row['address'] as String,
          label: row['label'] as String,
        ),
    ];
  }

  @override
  Future<void> upsert({required String address, required String label}) async {
    await _client.from(_table).upsert(
      {'address': address.toLowerCase(), 'label': label},
      // Matches `saved_wallets_user_address_key`, so saving the same wallet
      // twice updates its label instead of failing.
      onConflict: 'user_id,address',
    );
  }

  @override
  Future<void> remove(String address) async {
    await _client.from(_table).delete().eq('address', address.toLowerCase());
  }
}
