import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:wallet_wave/src/core/network/auth_interceptor.dart';
import 'package:wallet_wave/src/core/network/logging_interceptor.dart';

// Provides a secure storage instance globally for interceptors
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Provides the core configured Dio client
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl:
          'https://api.coingecko.com/api/v3', // Primary public market data endpoint
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add custom interceptors pipeline
  dio.interceptors.addAll([AuthInterceptor(ref), LoggingInterceptor()]);

  return dio;
});
