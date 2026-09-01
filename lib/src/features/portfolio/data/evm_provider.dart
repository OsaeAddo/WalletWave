import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'evm_client_service.dart';

// Public Ethereum Mainnet RPC URL
const String kEthereumRpcUrl = 'https://cloudflare-eth.com';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(() => client.close());
  return client;
});

final evmClientServiceProvider = Provider<EvmClientService>((ref) {
  final httpClient = ref.watch(httpClientProvider);
  final service = EvmClientService(
    rpcUrl: kEthereumRpcUrl,
    httpClient: httpClient,
  );

  ref.onDispose(() => service.dispose());
  return service;
});
