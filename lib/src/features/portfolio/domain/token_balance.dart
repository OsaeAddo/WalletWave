import 'dart:math' as math;

import 'ethereum_token.dart';

/// One on-chain token balance, still in its smallest unit (wei / token units).
///
/// Plain class instead of Freezed because `BigInt` has no ergonomic JSON
/// representation, and this value never leaves memory or crosses a network
/// boundary.
class TokenBalance {
  const TokenBalance({required this.token, required this.rawBalance});

  final EthereumToken token;

  /// `balanceOf(address)` as returned by the contract.
  final BigInt rawBalance;

  bool get hasBalance => rawBalance > BigInt.zero;

  double get amount =>
      rawBalance.toDouble() / math.pow(10, token.decimals).toDouble();

  /// Human-readable amount, e.g. `1250.42 USDC` → `1250.42`.
  ///
  /// Large values get two decimals, normal values four, dust six. Tiny non-zero
  /// balances are rendered as `<0.000001` instead of rounding to `0`.
  String get formattedAmount {
    final value = amount;
    if (value == 0) return '0';
    if (value < 0.000001) return '<0.000001';

    final decimals = value >= 1000 ? 2 : (value >= 1 ? 4 : 6);
    var text = value.toStringAsFixed(decimals);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    return text;
  }
}
