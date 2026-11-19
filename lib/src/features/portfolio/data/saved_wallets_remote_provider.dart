import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_providers.dart';
import 'saved_wallets_remote.dart';
import 'supabase_saved_wallets_remote.dart';

/// The cloud wallet store, or `null` when cloud sync is unavailable.
///
/// Keeping it nullable means callers must treat sync as optional, which is
/// exactly the product rule: the app works signed out and offline.
final savedWalletsRemoteProvider = Provider<SavedWalletsRemote?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseSavedWalletsRemote(client);
});
