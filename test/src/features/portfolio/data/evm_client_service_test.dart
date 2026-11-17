import 'package:wallet/wallet.dart';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wallet_wave/src/features/portfolio/data/evm_client_service.dart';

void main() {
  group('EvmClientService JSON-RPC Tests', () {
    const testWalletAddress = '0x0000000000000000000000000000000000000001';
    const testTokenContract = '0x0000000000000000000000000000000000000002';

    test('getNativeBalance parses eth_getBalance hex response into EtherAmount',
        () async {
      // 1 Ether in Wei = 1,000,000,000,000,000,000 Wei = 0xDE0B6B3A7640000 Hex
      const mockWeiHex = '0xde0b6b3a7640000';

      final mockHttpClient = MockClient((http.Request request) async {
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['method'], 'eth_getBalance');
        expect(body['params'][0], testWalletAddress);

        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': mockWeiHex,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final evmService = EvmClientService(
        rpcUrl: 'https://mock-rpc.internal',
        httpClient: mockHttpClient,
      );

      final balance = await evmService.getNativeBalance(testWalletAddress);

      expect(balance.getValueInUnit(EtherUnit.ether), 1.0);
      expect(balance.getInWei, BigInt.parse('1000000000000000000'));

      evmService.dispose();
    });

    test('getErc20Balance parses eth_call ABI response for balanceOf',
        () async {
      // Mocking 100 USDC balance (6 decimals -> 100,000,000 units = 0x5F5E100 Hex)
      // Contract ABI responses are padded to 32 bytes (64 hex characters)
      const mockResult32Bytes =
          '0x0000000000000000000000000000000000000000000000000000000005f5e100';

      final mockHttpClient = MockClient((http.Request request) async {
        expect(request.method, 'POST');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['method'], 'eth_call');

        final callParams = body['params'][0] as Map<String, dynamic>;
        expect(callParams['to'], testTokenContract);

        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': body['id'],
            'result': mockResult32Bytes,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final evmService = EvmClientService(
        rpcUrl: 'https://mock-rpc.internal',
        httpClient: mockHttpClient,
      );

      final erc20RawBalance = await evmService.getErc20Balance(
        tokenContractHex: testTokenContract,
        walletAddressHex: testWalletAddress,
      );

      expect(erc20RawBalance, BigInt.from(100000000));

      evmService.dispose();
    });

    test('getNativeBalance throws ArgumentError when address hex is malformed',
        () async {
      final mockHttpClient = MockClient((_) async => http.Response('', 500));

      final evmService = EvmClientService(
        rpcUrl: 'https://mock-rpc.internal',
        httpClient: mockHttpClient,
      );

      expect(
        () async => await evmService.getNativeBalance('invalid-address-format'),
        throwsArgumentError,
      );

      evmService.dispose();
    });
  });
}
