import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_coin.freezed.dart';
part 'market_coin.g.dart';

@freezed
abstract class MarketCoin with _$MarketCoin {
  const factory MarketCoin({
    required String id,
    required String symbol,
    required String name,
    @JsonKey(name: 'current_price') required double currentPrice,
    @JsonKey(name: 'price_change_percentage_24h') double? priceChange24h,
    @JsonKey(name: 'image') required String imageUrl,
  }) = _MarketCoin;

  factory MarketCoin.fromJson(Map<String, dynamic> json) =>
      _$MarketCoinFromJson(json);
}
