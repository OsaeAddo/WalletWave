import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../config/neon_providers.dart';
import 'auth_interceptor.dart';

/// The signed-in client for Neon's Data API, or `null` in offline builds.
///
/// A dedicated Dio instance matters: the auth interceptor must only ever be
/// attached to first-party backends. Registering it on the public CoinGecko
/// client would send the user's JWT to a third party.
final neonDataApiClientProvider = Provider<Dio?>((ref) {
  final config = ref.watch(neonConfigProvider);
  if (!config.hasUrls) return null;

  final auth = ref.watch(authRepositoryProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      readAccessToken: auth.currentAccessToken,
      // A 401 means the session is gone (expired or revoked elsewhere), not
      // just that this one request failed.
      onUnauthorized: () {
        auth.invalidateSession();
      },
    ),
  );

  return dio;
});
