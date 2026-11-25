import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../portfolio/application/saved_wallets_provider.dart';
import '../../portfolio/application/saved_wallets_realtime.dart';
import '../../portfolio/data/neon_realtime_client.dart';
import '../../portfolio/data/wallet_backup_service.dart';
import '../application/auth_providers.dart';
import '../domain/auth_error.dart';
import '../domain/auth_user.dart';

/// Sign in, create an account, or sign out.
///
/// Signing in is never required: it only turns on wallet sync across machines.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _creatingAccount = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Validate locally first so obvious mistakes do not need a round trip.
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Use a password with at least 6 characters.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final controller = ref.read(authControllerProvider);
    try {
      if (_creatingAccount) {
        await controller.signUp(email: email, password: password);
      } else {
        await controller.signIn(email: email, password: password);
      }
      if (!mounted) return;
      if (_creatingAccount) {
        _showMessage(
          'Account created. If email confirmation is on, check your inbox.',
        );
      } else {
        _showMessage('Signed in');
      }
      _passwordController.clear();
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      // Never leave the user staring at a raw stack trace.
      setState(() => _error = friendlyAuthError(error.toString()));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider).signOut();
      if (!mounted) return;
      _showMessage('Signed out. Your wallets stay on this device.');
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _backup() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final count =
          await ref.read(savedWalletsProvider.notifier).backupToCloud();
      if (!mounted) return;
      _showMessage('Backed up $count wallet${count == 1 ? '' : 's'}.');
    } on WalletBackupException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Backup failed. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final count =
          await ref.read(savedWalletsProvider.notifier).restoreFromCloud();
      if (!mounted) return;
      _showMessage('Restored $count wallet${count == 1 ? '' : 's'}.');
    } on WalletBackupException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Restore failed. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.valueOrNull;
    final available = ref.watch(authControllerProvider).isAvailable;
    final feed = ref.watch(savedWalletFeedProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: user == null
                ? _buildSignedOut(available)
                : _buildSignedIn(user, feed),
          ),
        ),
      ),
    );
  }

  Widget _buildSignedOut(bool available) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _creatingAccount ? 'Create an account' : 'Sign in',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Signing in syncs your saved wallets across machines. '
          'Everything else keeps working without an account.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        if (!available)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Cloud sync is not configured in this build. '
                'See the README "Cloud sync" section for the '
                '--dart-define values.',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ),
        TextField(
          controller: _emailController,
          enabled: !_submitting && available,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_submitting && available,
          obscureText: true,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Password',
            helperText: 'At least 6 characters',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: (!available || _submitting) ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_creatingAccount ? 'Create account' : 'Sign in'),
        ),
        TextButton(
          onPressed: _submitting
              ? null
              : () => setState(() {
                    _creatingAccount = !_creatingAccount;
                    _error = null;
                  }),
          child: Text(
            _creatingAccount
                ? 'I already have an account'
                : 'Create an account instead',
          ),
        ),
      ],
    );
  }

  Widget _buildSignedIn(AuthUser user, SavedWalletFeedUpdate? feed) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.cloud_done_outlined,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(
          'Signed in',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          user.email,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        _buildLiveStatus(theme, feed),
        const SizedBox(height: 16),
        Text(
          'Saved wallets sync to your account. '
          'They are also cached on this device, so the portfolio still works '
          'when you are offline or signed out.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Cloud backup', style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(
                  'Keep a JSON copy of your wallet list in your private '
                  'bucket. Restore merges it into this device; newer wallets '
                  'are never deleted.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _submitting ? null : _backup,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: const Text('Back up'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _restore,
                        icon: const Icon(Icons.cloud_download_outlined),
                        label: const Text('Restore'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _submitting ? null : _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }

  Widget _buildLiveStatus(ThemeData theme, SavedWalletFeedUpdate? feed) {
    final status = feed?.status;
    final latest = feed?.latest;

    final (IconData icon, Color color, String label) = switch (status) {
      null => (
          Icons.sync,
          theme.colorScheme.onSurfaceVariant,
          'Live sync: connecting…',
        ),
      SavedWalletFeedStatus.live => (
          Icons.bolt,
          theme.colorScheme.primary,
          latest == null
              ? 'Live sync connected'
              : 'Live sync connected · last ${latest.op}',
        ),
      SavedWalletFeedStatus.connecting => (
          Icons.sync,
          theme.colorScheme.onSurfaceVariant,
          'Live sync: reconnecting…',
        ),
      SavedWalletFeedStatus.error => (
          Icons.cloud_off,
          theme.colorScheme.error,
          feed?.message ?? 'Live sync offline',
        ),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
