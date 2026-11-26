import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'evm_client_service.dart';

/// Public Ethereum mainnet RPC.
///
/// Cloudflare's old `cloudflare-eth.com` endpoint now answers
/// "Cannot fulfill request", so it silently broke every balance read. This
/// endpoint is public and keyless; swap it here if it is ever retired.
const String kEthereumRpcUrl = 'https://ethereum-rpc.publicnode.com';

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
