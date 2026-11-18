import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/wallet.dart';
import 'package:wallet_wave/src/features/portfolio/application/portfolio_providers.dart';
import 'package:wallet_wave/src/features/portfolio/data/evm_client_service.dart';
import 'package:wallet_wave/src/features/portfolio/data/evm_provider.dart';
import 'package:wallet_wave/src/features/portfolio/domain/ethereum_token.dart';
import 'package:wallet_wave/src/features/portfolio/domain/portfolio_snapshot.dart';
import 'package:wallet_wave/src/features/portfolio/domain/token_balance.dart';

void main() {
  group('PortfolioNotifier', () {
    test('returns null when no address has been entered', () async {
      final container = _makeContainer(_FakeEvmClientService());
      addTearDown(container.dispose);

      final snapshot = await container.read(portfolioProvider.future);

      expect(snapshot, isNull);
    });

    test('combines the native balance with non-zero token balances', () async {
      final fakeService = _FakeEvmClientService(
        nativeWei: BigInt.from(2) * BigInt.from(10).pow(18),
        tokenBalances: {
          // 12.5 USDC (6 decimals).
          '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48': BigInt.from(12500000),
          // Zero balances must be hidden.
          '0xdAC17F958D2ee523a2206206994597C13D831ec7': BigInt.zero,
        },
      );
      final container = _makeContainer(fakeService);
      addTearDown(container.dispose);
      container.read(selectedAddressProvider.notifier).state =
          '0x000000000000000000000000000000000000dead';

      final snapshot = await container.read(portfolioProvider.future);

      expect(snapshot, isA<PortfolioSnapshot>());
      expect(snapshot!.nativeBalance.token.symbol, 'ETH');
      expect(snapshot.nativeBalance.formattedAmount, '2');
      expect(snapshot.tokenBalances, hasLength(1));
      expect(snapshot.tokenBalances.single.token.symbol, 'USDC');
      expect(snapshot.tokenBalances.single.formattedAmount, '12.5');
    });

    test('reports a readable error for a malformed address', () async {
      final container = _makeContainer(_FakeEvmClientService());
      addTearDown(container.dispose);
      container.read(selectedAddressProvider.notifier).state = 'not-an-address';

      await expectLater(
        container.read(portfolioProvider.future),
        throwsA(
          predicate(
            (error) => error.toString().contains('Invalid Ethereum address'),
          ),
        ),
      );
    });
  });

  group('TokenBalance formatting', () {
    test('trims trailing zeros and keeps small amounts readable', () {
      final usdc = kEthereumErc20Tokens.first;
      final dai = kEthereumErc20Tokens[2];
      expect(
        TokenBalance(rawBalance: BigInt.from(12500000), token: usdc)
            .formattedAmount,
        '12.5',
      );
      expect(
        TokenBalance(rawBalance: BigInt.from(1), token: dai).formattedAmount,
        '<0.000001',
      );
      expect(
        TokenBalance(rawBalance: BigInt.zero, token: usdc).formattedAmount,
        '0',
      );
    });
  });
}

ProviderContainer _makeContainer(EvmClientService service) {
  final container = ProviderContainer(
    overrides: [evmClientServiceProvider.overrideWithValue(service)],
  );
  return container;
}

/// Stand-in for the real JSON-RPC service: no network, fixed values.
class _FakeEvmClientService extends EvmClientService {
  _FakeEvmClientService({
    BigInt? nativeWei,
    this.tokenBalances = const <String, BigInt>{},
  })  : nativeWei = nativeWei ?? BigInt.zero,
        super(rpcUrl: 'https://unused.invalid');

  final BigInt nativeWei;
  final Map<String, BigInt> tokenBalances;

  @override
  Future<EtherAmount> getNativeBalance(String addressHex) async =>
      EtherAmount.inWei(nativeWei);

  @override
  Future<BigInt> getErc20Balance({
    required String tokenContractHex,
    required String walletAddressHex,
  }) async =>
      tokenBalances[tokenContractHex] ?? BigInt.zero;

  @override
  void dispose() {}
}
