import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '🌐 HTTP REQUEST [${options.method}] => PATH: ${options.path}',
      );
    }
    return handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      debugPrint(
        '✅ HTTP RESPONSE [${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
    }
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '❌ HTTP ERROR [${err.response?.statusCode}] => PATH: ${err.requestOptions.path} | MESSAGE: ${err.message}',
      );
    }
    return handler.next(err);
  }
}
