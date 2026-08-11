// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_coin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MarketCoin _$MarketCoinFromJson(Map<String, dynamic> json) => _MarketCoin(
  id: json['id'] as String,
  symbol: json['symbol'] as String,
  name: json['name'] as String,
  currentPrice: (json['current_price'] as num).toDouble(),
  priceChange24h: (json['price_change_percentage_24h'] as num?)?.toDouble(),
  imageUrl: json['image'] as String,
);

Map<String, dynamic> _$MarketCoinToJson(_MarketCoin instance) =>
    <String, dynamic>{
      'id': instance.id,
      'symbol': instance.symbol,
      'name': instance.name,
      'current_price': instance.currentPrice,
      'price_change_percentage_24h': instance.priceChange24h,
      'image': instance.imageUrl,
    };
