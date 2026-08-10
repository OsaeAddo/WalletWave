import 'package:dio/dio.dart';
import 'dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthInterceptor extends Interceptor {
  final Ref _ref;

  AuthInterceptor(this._ref);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Retrieve the secure token from storage
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'auth_token');

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Global handling for expired sessions or unauthorized access
    if (err.response?.statusCode == 401) {
      // TODO: Trigger global logout state or refresh token flow
    }
    return handler.next(err);
  }
}
