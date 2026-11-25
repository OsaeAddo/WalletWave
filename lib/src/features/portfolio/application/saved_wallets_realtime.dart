import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/neon_providers.dart';
import '../../../core/network/neon_clients.dart';
import '../../auth/application/auth_providers.dart';
import '../data/neon_realtime_client.dart';

/// Live signals from the `saved_wallets_events` change feed.
///
/// The feed is only a notification channel: rows come back as ids and
/// operations, and the wallet list itself is always re-read through the Data
/// API so Row Level Security applies. Signed-out and unconfigured builds get an
/// empty stream, which keeps the app fully usable without a network.
final savedWalletFeedProvider = StreamProvider<SavedWalletFeedUpdate>((ref) {
  final config = ref.watch(neonConfigProvider);
  final user = ref.watch(authStateProvider).valueOrNull;
  final api = ref.watch(neonDataApiClientProvider);

  if (user == null || !config.hasRealtime || api == null) {
    return const Stream.empty();
  }

  final client = NeonRealtimeClient(
    // The URL is public; the capability fetched below is the credential.
    url: Uri.parse(config.realtimeSocketUrl),
    fetchTicket: () => _fetchTicket(api, config.functionsUrl),
  );
  ref.onDispose(client.dispose);
  client.start();
  return client.updates;
});

/// Asks the function for one sealed capability.
///
/// A `401` means the session is gone, not that the network failed, so it is
/// returned as `null` and the client stops retrying until the user signs in
/// again (the provider rebuilds on auth changes).
Future<RealtimeTicket?> _fetchTicket(Dio api, String functionsUrl) async {
  try {
    final response = await api.post<Map<String, dynamic>>(
      '$functionsUrl/realtime/ticket',
    );
    final data = response.data;
    if (data == null) return null;
    return RealtimeTicket.fromJson(data);
  } on DioException catch (error) {
    if (error.response?.statusCode == 401) return null;
    rethrow;
  }
}
