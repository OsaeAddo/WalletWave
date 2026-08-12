import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/router/app_router.dart';
import 'src/core/database/isar_provider.dart'; // Added import

void main() async {
  // Required because we are executing async code before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database natively
  final isar = await initIsar();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized instance globally
        isarProvider.overrideWithValue(isar),
      ],
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
