import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/usd.dart';
import '../../auth/presentation/auth_action_button.dart';
import '../application/portfolio_providers.dart';
import '../application/portfolio_valuation_provider.dart';
import '../application/saved_wallets_provider.dart';
import '../domain/portfolio_valuation.dart';
import '../domain/saved_wallet.dart';

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
    await ref.read(savedWalletsProvider.notifier).remove(wallet);
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
    // Valuation watches balances and prices, so live ticks repaint the dollars
    // without re-running the RPC calls.
    final portfolioAsync = ref.watch(portfolioValuationProvider);
    final savedWallets =
        ref.watch(savedWalletsProvider).valueOrNull ?? const [];
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EVM Portfolio'),
        actions: [
          const AuthActionButton(),
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
                data: (valuation) => valuation == null
                    ? const _EmptyPrompt()
                    : _PortfolioView(valuation: valuation),
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
  const _PortfolioView({required this.valuation});

  final PortfolioValuation valuation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final native = valuation.assets.first;
    final tokens = valuation.assets.skip(1);

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portfolio value',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  // A dash is honest: nothing could be priced.
                  valuation.totalUsd == null
                      ? '—'
                      : formatUsd(valuation.totalUsd!),
                  style: theme.textTheme.headlineMedium,
                ),
                if (!valuation.isComplete) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Excludes ${valuation.unpricedCount} '
                    '${valuation.unpricedCount == 1 ? 'asset' : 'assets'} '
                    'with no market price.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const Divider(height: 32),
                _BalanceLine(
                  label: '${native.balance.formattedAmount} '
                      '${native.balance.token.symbol}',
                  valueUsd: native.valueUsd,
                ),
                const SizedBox(height: 12),
                Text(
                  shortAddress(valuation.address),
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
        if (tokens.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('No tracked ERC-20 balances for this address.'),
          )
        else
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final asset in tokens) _TokenRow(asset: asset),
              ],
            ),
          ),
      ],
    );
  }
}

class _BalanceLine extends StatelessWidget {
  const _BalanceLine({required this.label, required this.valueUsd});

  final String label;
  final double? valueUsd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        const Spacer(),
        Text(
          valueUsd == null ? 'no price' : formatUsd(valueUsd!),
          style: theme.textTheme.titleMedium?.copyWith(
            color: valueUsd == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({required this.asset});

  final AssetValuation asset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueUsd = asset.valueUsd;

    return ListTile(
      title: Text(asset.balance.token.symbol),
      subtitle: Text(asset.balance.token.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            asset.balance.formattedAmount,
            style: theme.textTheme.titleMedium,
          ),
          Text(
            valueUsd == null ? 'no price' : formatUsd(valueUsd),
            style: theme.textTheme.bodySmall?.copyWith(
              color: valueUsd == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
