import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timed out. Please check your internet.',
        );
      case DioExceptionType.badResponse:
        return ApiException('Server error: ${error.response?.statusCode}');
      case DioExceptionType.connectionError:
        return ApiException('No internet connection.');
      default:
        return ApiException('An unexpected network error occurred.');
    }
  }

  @override
  String toString() => message;
}
