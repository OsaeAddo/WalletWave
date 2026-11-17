import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Hosts the app's top-level tabs.
///
/// The shell owns only the navigation bar; each branch supplies its own
/// [Scaffold] and [AppBar]. [navigationShell] is provided by
/// [StatefulShellRoute.indexedStack], which keeps every branch alive so tab
/// state (scroll position, form input) survives switching.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.show_chart),
      label: 'Markets',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet),
      label: 'Portfolio',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: _destinations,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Re-tapping the active tab returns it to its root screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
