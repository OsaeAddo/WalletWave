import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_providers.dart';

/// App-bar shortcut to the account screen.
///
/// The icon changes once a user is signed in, so cloud sync is discoverable
/// without a permanent banner or a third tab.
class AuthActionButton extends ConsumerWidget {
  const AuthActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(
      authStateProvider.select((state) => state.valueOrNull?.email),
    );

    return IconButton(
      tooltip:
          email == null ? 'Sign in to sync wallets' : 'Signed in as $email',
      icon: Icon(
        email == null ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
      ),
      onPressed: () => context.push('/account'),
    );
  }
}
