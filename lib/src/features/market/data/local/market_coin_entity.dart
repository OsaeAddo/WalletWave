import 'package:isar_community/isar.dart';

part 'market_coin_entity.g.dart';

@collection
class MarketCoinEntity {
  Id id = Isar.autoIncrement; // for Isar's internal tracking

  // index the API's string ID (e.g., 'bitcoin') so existing records  can easily
  // be replaced instead of creating duplicates on refresh.
  @Index(unique: true, replace: true)
  late String coinId;

  late String symbol;
  late String name;
  late double currentPrice;
  double? priceChange24h;
  late String imageUrl;
}
