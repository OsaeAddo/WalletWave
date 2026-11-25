import 'package:dio/dio.dart';

/// Adds `Authorization: Bearer <token>` to outgoing requests.
///
/// Registered on the Neon Data API / functions client only. Never register it
/// on the public CoinGecko client: that would leak a user's token to a third
/// party.
///
/// The token is passed as a callback rather than read from storage here, so the
/// interceptor has no opinion about where sessions live and is trivial to test.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Future<String?> Function() readAccessToken,
    void Function()? onUnauthorized,
  })  : _readAccessToken = readAccessToken,
        _onUnauthorized = onUnauthorized;

  final Future<String?> Function() _readAccessToken;
  final void Function()? _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    } catch (error, stackTrace) {
      // Failing to read a token is not a reason to drop the request; the
      // server will answer 401 if it matters.
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // A 401 normally means the access token expired and could not be refreshed.
    if (err.response?.statusCode == 401) {
      _onUnauthorized?.call();
    }
    handler.next(err);
  }
}
