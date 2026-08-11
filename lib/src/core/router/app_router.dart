// import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/market/presentation/market_dashboard_screen.dart';

// Providing the router globally allows us to inject state-based redirect logic later.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MarketDashboardScreen(),
      ),
    ],
  );
});
