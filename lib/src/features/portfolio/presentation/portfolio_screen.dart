import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/portfolio_providers.dart';
import '../application/saved_wallets_provider.dart';
import '../domain/portfolio_snapshot.dart';
import '../domain/saved_wallet.dart';
import '../domain/token_balance.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: ref.read(selectedAddressProvider),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _loadAddress([String? address]) {
    final value = (address ?? _addressController.text).trim();
    if (address != null) _addressController.text = value;
    FocusScope.of(context).unfocus();
    ref.read(selectedAddressProvider.notifier).state = value;
  }

  Future<void> _saveAddress() async {
    FocusScope.of(context).unfocus();
    try {
      await ref
          .read(savedWalletsProvider.notifier)
          .save(_addressController.text);
      if (!mounted) return;
      _showMessage('Wallet saved');
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _removeWallet(SavedWallet wallet) async {
    await ref.read(savedWalletsProvider.notifier).remove(wallet.id);
    if (!mounted) return;
    _showMessage('${wallet.label} removed');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final portfolioAsync = ref.watch(portfolioProvider);
    final savedWallets =
        ref.watch(savedWalletsProvider).valueOrNull ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVM Portfolio'),
        actions: [
          IconButton(
            tooltip: 'Refresh balances',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(portfolioProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _addressController,
              onSubmitted: (_) => _loadAddress(),
              decoration: InputDecoration(
                labelText: 'EVM Wallet Address',
                hintText: '0x...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Load balances',
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _loadAddress,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _loadAddress,
                  icon: const Icon(Icons.search),
                  label: const Text('Load'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _saveAddress,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save'),
                ),
              ],
            ),
            if (savedWallets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Saved wallets', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final wallet in savedWallets)
                    InputChip(
                      avatar:
                          const Icon(Icons.account_balance_wallet, size: 18),
                      label: Text(wallet.label),
                      onPressed: () => _loadAddress(wallet.address),
                      // Built-in chip delete icon keeps removal discoverable.
                      onDeleted: () => _removeWallet(wallet),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Expanded(
              child: portfolioAsync.when(
                data: (snapshot) => snapshot == null
                    ? const _EmptyPrompt()
                    : _PortfolioView(snapshot: snapshot),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => _ErrorView(message: _friendlyError(error)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Strips Dart's `Exception: ` prefix so users see plain language.
  String _friendlyError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}

class _EmptyPrompt extends StatelessWidget {
  const _EmptyPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Enter an EVM address to load its native and token balances.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.error),
          ),
        ],
      ),
    );
  }
}

class _PortfolioView extends StatelessWidget {
  const _PortfolioView({required this.snapshot});

  final PortfolioSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Native Balance',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.nativeBalance.formattedAmount} '
                  '${snapshot.nativeBalance.token.symbol}',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  shortAddress(snapshot.address),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Tokens', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (snapshot.tokenBalances.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No tracked ERC-20 balances for this address.'),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final balance in snapshot.tokenBalances)
                  _TokenRow(balance: balance),
              ],
            ),
          ),
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.balance});

  final TokenBalance balance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(balance.token.symbol),
      subtitle: Text(balance.token.name),
      trailing: Text(
        balance.formattedAmount,
        style: theme.textTheme.titleMedium,
      ),
    );
  }
}
