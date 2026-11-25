import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/core/config/neon_config.dart';
import 'src/core/config/neon_providers.dart';
import 'src/core/database/isar_provider.dart';
import 'src/core/router/app_router.dart';
import 'src/features/auth/application/auth_providers.dart';
import 'src/features/auth/data/neon_auth_repository.dart';
import 'src/features/auth/data/neon_session_store.dart';

Future<void> main() async {
  // Required because we are executing async code before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database natively.
  final isar = await initIsar();

  final overrides = <Override>[isarProvider.overrideWithValue(isar)];

  // Cloud sync is opt-in at build time. Without config the app runs exactly as
  // before, just signed out forever, which is a supported way to use it.
  //
  // Neon needs no SDK bootstrap: the repository talks to the auth server over
  // HTTP, so a bad URL only fails when someone actually signs in.
  if (NeonConfig.isConfigured) {
    final config = NeonConfig.current;
    overrides.add(neonConfigProvider.overrideWithValue(config));
    overrides.add(
      authRepositoryProvider.overrideWithValue(
        NeonAuthRepository(
          config: config,
          sessionStore: NeonSessionStore(),
        ),
      ),
    );
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
