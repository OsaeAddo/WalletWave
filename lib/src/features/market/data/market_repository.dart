import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../../core/database/isar_provider.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_exception.dart';
import '../domain/market_coin.dart';
import 'local/market_coin_entity.dart';
import 'local/market_coin_mapper.dart';

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(
    ref.watch(dioProvider),
    ref.watch(isarProvider),
  );
});

class MarketRepository {
  final Dio _dio;
  final Isar _isar;

  MarketRepository(this._dio, this._isar);

  /// Reads cached records directly from Isar
  Future<List<MarketCoin>> getCachedMarketCoins() async {
    final entities = await _isar.marketCoinEntitys.where().findAll();
    return entities.map((e) => e.toDomain()).toList();
  }

  /// Fetches from the REST endpoint and writes to Isar local storage
  Future<List<MarketCoin>> fetchAndCacheMarketCoins() async {
    try {
      final response = await _dio.get(
        '/coins/markets',
        queryParameters: {
          'vs_currency': 'usd',
          'order': 'market_cap_desc',
          'per_page': 50,
          'page': 1,
          'sparkline': false,
        },
      );

      final List<dynamic> data = response.data;
      final coins = data.map((json) => MarketCoin.fromJson(json)).toList();

      // Persist network results into Isar via a write transaction
      await _isar.writeTxn(() async {
        final entities = coins.map((c) => c.toEntity()).toList();
        await _isar.marketCoinEntitys.putAll(entities);
      });

      return coins;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException('Failed to parse market data.');
    }
  }
}
