import 'package:web3dart/web3dart.dart';
import 'package:wallet/wallet.dart';
import 'package:http/http.dart' as http;

class EvmClientService {
  final Web3Client _web3client;

  EvmClientService({required String rpcUrl, http.Client? httpClient})
      : _web3client = Web3Client(rpcUrl, httpClient ?? http.Client());

  /// Fetches the native cryptocurrency balance (e.g., ETH, MATIC, BNB) for an address.
  Future<EtherAmount> getNativeBalance(String addressHex) async {
    final address = EthereumAddress.fromHex(addressHex);
    return await _web3client.getBalance(address);
  }

  /// Executes a low-level `eth_call` to read an ERC-20 token balance using `balanceOf(address)`.
  Future<BigInt> getErc20Balance({
    required String tokenContractHex,
    required String walletAddressHex,
  }) async {
    final contractAddress = EthereumAddress.fromHex(tokenContractHex);
    final walletAddress = EthereumAddress.fromHex(walletAddressHex);

    // Minimal ERC-20 ABI declaration for the balanceOf function
    final contract = DeployedContract(
      ContractAbi.fromJson(
        '''[
          {
            "constant": true,
            "inputs": [{"name": "_owner", "type": "address"}],
            "name": "balanceOf",
            "outputs": [{"name": "balance", "type": "uint256"}],
            "type": "function"
          }
        ]''',
        'ERC20BalanceOf',
      ),
      contractAddress,
    );

    final balanceOfFunction = contract.function('balanceOf');

    final result = await _web3client.call(
      contract: contract,
      function: balanceOfFunction,
      params: [walletAddress],
    );

    if (result.isNotEmpty && result.first is BigInt) {
      return result.first as BigInt;
    }
    return BigInt.zero;
  }

  /// Closes the HTTP connection when the client service is destroyed.
  void dispose() {
    _web3client.dispose();
  }
}
