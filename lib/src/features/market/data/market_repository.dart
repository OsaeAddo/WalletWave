import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/network/api_exception.dart';
import '../domain/market_coin.dart';

// Expose the repository via Riverpod
final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return MarketRepository(ref.watch(dioProvider));
});

class MarketRepository {
  final Dio _dio;

  MarketRepository(this._dio);

  Future<List<MarketCoin>> fetchMarketCoins() async {
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
      return data.map((json) => MarketCoin.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException('Failed to parse market data.');
    }
  }
}
