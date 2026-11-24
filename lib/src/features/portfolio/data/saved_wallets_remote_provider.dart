import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/neon_providers.dart';
import '../../../core/network/neon_clients.dart';
import 'neon_saved_wallets_remote.dart';
import 'saved_wallets_remote.dart';

/// The cloud wallet store, or `null` when cloud sync is unavailable.
///
/// Keeping it nullable means callers must treat sync as optional, which is
/// exactly the product rule: the app works signed out and offline.
final savedWalletsRemoteProvider = Provider<SavedWalletsRemote?>((ref) {
  final client = ref.watch(neonDataApiClientProvider);
  if (client == null) return null;
  return NeonSavedWalletsRemote(
    config: ref.watch(neonConfigProvider),
    dio: client,
  );
});
