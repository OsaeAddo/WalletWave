import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/core/config/supabase_config.dart';
import 'src/core/config/supabase_providers.dart';
import 'src/core/database/isar_provider.dart';
import 'src/core/router/app_router.dart';
import 'src/features/auth/application/auth_providers.dart';
import 'src/features/auth/data/secure_session_storage.dart';
import 'src/features/auth/data/supabase_auth_repository.dart';

Future<void> main() async {
  // Required because we are executing async code before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database natively.
  final isar = await initIsar();

  final overrides = <Override>[isarProvider.overrideWithValue(isar)];

  // Cloud sync is opt-in at build time. Without keys the app runs exactly as
  // before, just signed out forever, which is a supported way to use it.
  if (SupabaseConfig.isConfigured) {
    try {
      final supabase = await Supabase.initialize(
        url: SupabaseConfig.current.url,
        // Named `publishableKey` in the SDK; legacy anon keys work here too.
        publishableKey: SupabaseConfig.current.anonKey,
        authOptions: FlutterAuthClientOptions(
          // Store the refresh token in the OS keyring, not a plain file.
          localStorage: SecureSessionStorage(),
          // No OAuth deep links on Linux desktop, so do not start a listener.
          detectSessionInUri: false,
        ),
      );

      overrides.add(supabaseClientProvider.overrideWithValue(supabase.client));
      overrides.add(
        authRepositoryProvider.overrideWithValue(
          SupabaseAuthRepository(supabase.client),
        ),
      );
    } catch (error) {
      // A misconfigured backend must not stop the offline app from starting.
      debugPrint('Supabase init failed; continuing without cloud sync: $error');
    }
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const WalletWaveApp(),
    ),
  );
}

class WalletWaveApp extends ConsumerWidget {
  const WalletWaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'WalletWave',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
