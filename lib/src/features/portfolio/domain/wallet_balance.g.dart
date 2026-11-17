// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_balance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WalletBalance _$WalletBalanceFromJson(Map<String, dynamic> json) =>
    _WalletBalance(
      address: json['address'] as String,
      nativeBalanceEther: (json['nativeBalanceEther'] as num).toDouble(),
      symbol: json['symbol'] as String,
    );

Map<String, dynamic> _$WalletBalanceToJson(_WalletBalance instance) =>
    <String, dynamic>{
      'address': instance.address,
      'nativeBalanceEther': instance.nativeBalanceEther,
      'symbol': instance.symbol,
    };
