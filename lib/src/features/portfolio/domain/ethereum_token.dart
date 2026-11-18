/// A token the portfolio screen knows how to read.
///
/// Keeping the list static is deliberate: symbol, name and `decimals` are
/// metadata that a plain ERC-20 contract does not expose in `balanceOf`, so
/// fetching them would cost one extra RPC call per token. A curated list of
/// well-known Ethereum mainnet tokens is cheap and predictable.
class EthereumToken {
  const EthereumToken({
    required this.symbol,
    required this.name,
    required this.decimals,
    required this.contractAddress,
  });

  final String symbol;
  final String name;

  /// How many decimal places the raw integer balance has.
  final int decimals;
  final String contractAddress;
}

/// Native ETH is not a contract, so it has no address.
const kNativeEthereumToken = EthereumToken(
  symbol: 'ETH',
  name: 'Ethereum',
  decimals: 18,
  contractAddress: '',
);

/// Tokens shown on the portfolio screen.
///
/// Addresses are Ethereum mainnet contracts. Add entries here to track more.
const kEthereumErc20Tokens = <EthereumToken>[
  EthereumToken(
    symbol: 'USDC',
    name: 'USD Coin',
    decimals: 6,
    contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  ),
  EthereumToken(
    symbol: 'USDT',
    name: 'Tether USD',
    decimals: 6,
    contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
  ),
  EthereumToken(
    symbol: 'DAI',
    name: 'Dai Stablecoin',
    decimals: 18,
    contractAddress: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
  ),
  EthereumToken(
    symbol: 'LINK',
    name: 'Chainlink',
    decimals: 18,
    contractAddress: '0x514910771AF9Ca656af840dff83E8264EcF986CA',
  ),
];
