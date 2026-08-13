import '../../domain/market_coin.dart';
import 'market_coin_entity.dart';

extension MarketCoinMapper on MarketCoin {
  /// Converts a network DTO to a local Isar entity
  MarketCoinEntity toEntity() {
    return MarketCoinEntity()
      ..coinId = id
      ..symbol = symbol
      ..name = name
      ..currentPrice = currentPrice
      ..priceChange24h = priceChange24h
      ..imageUrl = imageUrl;
  }
}

extension MarketCoinEntityMapper on MarketCoinEntity {
  /// Converts a local Isar entity back to a domain model
  MarketCoin toDomain() {
    return MarketCoin(
      id: coinId,
      symbol: symbol,
      name: name,
      currentPrice: currentPrice,
      priceChange24h: priceChange24h,
      imageUrl: imageUrl,
    );
  }
}
