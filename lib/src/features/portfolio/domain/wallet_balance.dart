import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_balance.freezed.dart';
part 'wallet_balance.g.dart';

@freezed
abstract class WalletBalance with _$WalletBalance {
  const factory WalletBalance({
    required String address,
    required double nativeBalanceEther,
    required String symbol,
  }) = _WalletBalance;

  factory WalletBalance.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceFromJson(json);
}
