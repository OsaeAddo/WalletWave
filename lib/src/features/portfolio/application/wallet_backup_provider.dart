import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/neon_providers.dart';
import '../../../core/network/neon_clients.dart';
import '../data/wallet_backup_service.dart';

/// Cloud backup, or `null` when the build has no `api` function URL.
///
/// Keeping it nullable lets the UI explain that backup is unavailable instead
/// of attempting a request that can only fail.
final walletBackupServiceProvider = Provider<WalletBackupService?>((ref) {
  final config = ref.watch(neonConfigProvider);
  final api = ref.watch(neonDataApiClientProvider);
  if (!config.hasFunctions || api == null) return null;
  return WalletBackupService(config: config, api: api);
});
