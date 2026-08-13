import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:isar_community/isar.dart';

// Import your app files
import 'package:wallet_wave/src/features/market/data/market_repository.dart';
import 'package:wallet_wave/src/features/market/data/local/market_coin_entity.dart';
import 'package:wallet_wave/src/features/market/domain/market_coin.dart';

// Create a mock for the Dio network client
class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late Isar isar;
  late MarketRepository repository;
  late Directory tempDir;

  // Runs once before all tests
  setUpAll(() async {
    // Crucial for unit testing: Downloads the Isar Core native binaries
    // for your Linux host environment since tests run outside of Flutter.
    await Isar.initializeIsarCore(download: true);
  });

  // Runs before every individual test
  setUp(() async {
    mockDio = MockDio();

    // Create an isolated temporary directory for the database
    tempDir = Directory.systemTemp.createTempSync(
        'isar_test_dir_${DateTime.now().millisecondsSinceEpoch}');

    isar = await Isar.open(
      [MarketCoinEntitySchema],
      directory: tempDir.path,
    );

    repository = MarketRepository(mockDio, isar);
  });

  // Runs after every individual test
  tearDown(() async {
    // Close the database and wipe the disk so tests don't pollute each other
    await isar.close(deleteFromDisk: true);
  });

  test('getCachedMarketCoins returns domain models when Isar cache exists',
      () async {
    // 1. Arrange: Insert dummy data directly into the Isar database
    final entity = MarketCoinEntity()
      ..coinId = 'bitcoin'
      ..symbol = 'btc'
      ..name = 'Bitcoin'
      ..currentPrice = 60000.0
      ..priceChange24h = 5.0
      ..imageUrl = 'https://example.com/btc.png';

    await isar.writeTxn(() async {
      await isar.marketCoinEntitys.put(entity);
    });

    // 2. Act: Execute the cache retrieval method
    final result = await repository.getCachedMarketCoins();

    // 3. Assert: Verify the data was retrieved and mapped correctly
    expect(result.length, 1);
    expect(result.first.id, 'bitcoin');
    expect(result.first.currentPrice, 60000.0);
    expect(result.first, isA<MarketCoin>());
  });

  test('fetchAndCacheMarketCoins fetches from Dio and persists to Isar',
      () async {
    // 1. Arrange: Mock the expected JSON response from the REST API
    final mockJsonResponse = [
      {
        "id": "ethereum",
        "symbol": "eth",
        "name": "Ethereum",
        "image": "https://example.com/eth.png",
        "current_price": 3000.0,
        "price_change_percentage_24h": -1.2
      }
    ];

    // Intercept the Dio GET request and return a fake 200 OK response
    when(() => mockDio.get(
          '/coins/markets',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => Response(
          requestOptions: RequestOptions(path: '/coins/markets'),
          data: mockJsonResponse,
          statusCode: 200,
        ));

    // 2. Act: Execute the repository fetch logic
    final result = await repository.fetchAndCacheMarketCoins();

    // 3. Assert: Verify the returned Domain Models match the API data
    expect(result.length, 1);
    expect(result.first.id, 'ethereum');
    expect(result.first.name, 'Ethereum');

    // 4. Assert: Verify the database was successfully populated with the new data
    final cachedEntities = await isar.marketCoinEntitys.where().findAll();
    expect(cachedEntities.length, 1);
    expect(cachedEntities.first.coinId, 'ethereum');
  });
}
