// End-to-end check against the real Neon branch.
//
// Not part of `flutter test`: run it explicitly once the backend is deployed.
//
//   bash tool/flutter-env.sh
//   NEON_E2E_EMAIL=... NEON_E2E_PASSWORD=... \
//     flutter test tool/e2e/neon_sync_e2e_test.dart
//
// It signs in with the real auth server, writes through the Data API, uploads
// and downloads a backup through the function + Object Storage, and waits for a
// Realtime event caused by its own insert. The account should be a dedicated
// test account: the backup file is replaced with this test's wallet list.

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/core/config/neon_config.dart';
import 'package:wallet_wave/src/core/network/auth_interceptor.dart';
import 'package:wallet_wave/src/features/auth/data/neon_auth_repository.dart';
import 'package:wallet_wave/src/features/auth/data/neon_session_store.dart';
import 'package:wallet_wave/src/features/portfolio/data/neon_realtime_client.dart';
import 'package:wallet_wave/src/features/portfolio/data/neon_saved_wallets_remote.dart';
import 'package:wallet_wave/src/features/portfolio/data/wallet_backup_service.dart';
import 'package:wallet_wave/src/features/portfolio/domain/saved_wallet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The Flutter test binding installs a fake HttpClient that returns 400 for
  // every request. This file deliberately talks to the real backend, so
  // restore the real implementation.
  setUpAll(() => HttpOverrides.global = null);

  final config = _configFromFlutterEnv();
  final email = Platform.environment['NEON_E2E_EMAIL'];
  final password = Platform.environment['NEON_E2E_PASSWORD'];
  final skipReason = config == null || email == null || password == null
      ? 'Needs .env.flutter (tool/flutter-env.sh) and NEON_E2E_EMAIL/'
          'NEON_E2E_PASSWORD.'
      : null;

  test(
    'sign in, write, back up, restore and observe a live event',
    () async {
      final cfg = config!;
      final auth = NeonAuthRepository(
        config: cfg,
        sessionStore: NeonSessionStore(),
      );

      await auth.signInWithPassword(email: email!, password: password!);
      addTearDown(auth.signOut);
      expect(auth.currentUser, isNotNull);
      expect(await auth.currentAccessToken(), isNotNull);

      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      dio.interceptors.add(
        AuthInterceptor(readAccessToken: auth.currentAccessToken),
      );

      final remote = NeonSavedWalletsRemote(config: cfg, dio: dio);
      final first = _randomAddress();
      await remote.upsert(address: first, label: 'E2E backup');
      addTearDown(() => remote.remove(first));

      final all = await remote.fetchAll();
      expect(all.map((wallet) => wallet.address), contains(first));

      // --- Object Storage: upload, then download the same bytes ---
      final backup = WalletBackupService(config: cfg, api: dio);
      await backup.backup([
        for (final wallet in all)
          SavedWallet(id: 0, address: wallet.address, label: wallet.label),
      ]);

      final downloaded = await backup.download();
      expect(downloaded, isNotNull);
      expect(
        downloaded!.map((entry) => entry.address),
        contains(first),
      );

      // --- Realtime: wait for a live baseline, then cause an insert ---
      final baseline = Completer<SavedWalletFeedUpdate>();
      final causedByUs = Completer<SavedWalletFeedUpdate>();
      int? baselineId;

      final client = NeonRealtimeClient(
        url: Uri.parse(cfg.realtimeSocketUrl),
        fetchTicket: () => _fetchTicket(dio, cfg),
      );
      final updates = client.updates.listen((update) {
        if (update.status == SavedWalletFeedStatus.error) {
          if (!baseline.isCompleted) {
            baseline.completeError(
              StateError(update.message ?? 'Live sync failed'),
            );
          }
          return;
        }
        if (update.status != SavedWalletFeedStatus.live) return;
        if (!baseline.isCompleted) {
          baselineId = update.latest?.id ?? 0;
          baseline.complete(update);
        } else if (!causedByUs.isCompleted &&
            (update.latest?.id ?? 0) > (baselineId ?? 0)) {
          causedByUs.complete(update);
        }
      });
      addTearDown(() async {
        await updates.cancel();
        await client.dispose();
      });

      client.start();
      final live = await baseline.future.timeout(const Duration(seconds: 45));
      expect(live.status, SavedWalletFeedStatus.live);

      final second = _randomAddress();
      await remote.upsert(address: second, label: 'E2E live');
      addTearDown(() => remote.remove(second));

      final event =
          await causedByUs.future.timeout(const Duration(seconds: 45));
      expect(event.rows.map((row) => row.op), contains('insert'));
    },
    skip: skipReason,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

NeonConfig? _configFromFlutterEnv() {
  final file = File('.env.flutter');
  if (!file.existsSync()) return null;

  final values = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final split = trimmed.indexOf('=');
    if (split <= 0) continue;
    values[trimmed.substring(0, split)] = trimmed.substring(split + 1);
  }

  final auth = values['NEON_AUTH_BASE_URL'];
  final data = values['NEON_DATA_API_URL'];
  final functions = values['NEON_FUNCTIONS_BASE_URL'];
  final realtime = values['NEON_REALTIME_URL'];
  if (auth == null || data == null || functions == null || realtime == null) {
    return null;
  }
  return NeonConfig(
    authBaseUrl: auth,
    dataApiUrl: data,
    functionsBaseUrl: functions,
    realtimeUrl: realtime,
  );
}

Future<RealtimeTicket?> _fetchTicket(Dio dio, NeonConfig config) async {
  final response = await dio.post<Map<String, dynamic>>(
    '${config.functionsUrl}/realtime/ticket',
  );
  final data = response.data;
  if (data == null) return null;
  return RealtimeTicket.fromJson(data);
}

/// A syntactically valid address nobody else is using.
String _randomAddress() {
  const hex = '0123456789abcdef';
  final random = Random.secure();
  return '0x${List.generate(40, (_) => hex[random.nextInt(16)]).join()}';
}
