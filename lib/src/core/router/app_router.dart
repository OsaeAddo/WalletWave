import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/market/presentation/market_dashboard_screen.dart';
import '../../features/portfolio/presentation/portfolio_screen.dart';
import 'app_shell.dart';

// Providing the router globally allows us to inject state-based redirect logic later.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/markets',
    routes: [
      // Keep old deep links working: '/' used to be the market screen.
      GoRoute(
        path: '/',
        redirect: (context, state) => '/markets',
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/markets',
                builder: (context, state) => const MarketDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
