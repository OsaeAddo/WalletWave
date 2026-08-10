import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: WalletWaveApp()));
}

class WalletWaveApp extends ConsumerWidget {
  const WalletWaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider to reactively handle navigation
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'WalletWave',
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
