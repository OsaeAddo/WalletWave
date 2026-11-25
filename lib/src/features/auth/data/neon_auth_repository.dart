import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/neon_config.dart';
import '../domain/auth_error.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';
import 'neon_session_store.dart';

/// The cookie Neon Auth issues. It is what actually authenticates the session;
/// a plain bearer token is not accepted by the auth server.
const neonSessionCookieName = '__Secure-neon-auth.session_token';

/// Pulls the session cookie pair out of `Set-Cookie` headers.
///
/// Only the `name=value` part is kept: attributes such as `Path` and `HttpOnly`
/// are for browsers, while Dio sends the pair back verbatim.
String? sessionCookieFromSetCookie(List<String>? setCookies) {
  for (final raw in setCookies ?? const <String>[]) {
    final pair = raw.split(';').first.trim();
    if (pair.startsWith('$neonSessionCookieName=')) return pair;
  }
  return null;
}

/// Reads the `exp` claim so a short-lived JWT can be reused instead of fetching
/// a new one for every request. Returns `null` when the token is malformed.
DateTime? jwtExpiry(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    final exp = payload is Map ? payload['exp'] : null;
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000, isUtc: true);
  } catch (_) {
    return null;
  }
}

/// [AuthRepository] backed by Neon Auth (Managed Better Auth).
///
/// Password hashing, token refresh and rate limiting happen on Neon's servers.
/// This class keeps the session cookie, caches the 15-minute JWT that the Data
/// API expects, and translates backend errors into plain language.
class NeonAuthRepository implements AuthRepository {
  NeonAuthRepository({
    required NeonConfig config,
    required NeonSessionStore sessionStore,
    Dio? dio,
  })  : _config = config,
        _store = sessionStore,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
              ),
            ) {
    _ready = _restore();
  }

  final NeonConfig _config;
  final NeonSessionStore _store;
  final Dio _dio;

  final _changes = StreamController<AuthUser?>.broadcast();

  late final Future<void> _ready;
  AuthUser? _user;
  String? _cookie;
  String? _jwt;
  DateTime? _jwtExpiry;

  @override
  bool get isAvailable => true;

  @override
  AuthUser? get currentUser => _user;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    // Replay the restored session first so the UI never flickers signed-out.
    await _ready;
    yield _user;
    yield* _changes.stream;
  }

  Future<void> _restore() async {
    final session = await _store.read();
    if (session == null) return;
    _cookie = session.cookie;
    _user = AuthUser(id: session.userId, email: session.email);
    _changes.add(_user);
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final result = await _post('/sign-in/email', {
      'email': email.trim(),
      'password': password,
    });
    final user = await _acceptSession(result.data, result.cookie);
    if (user == null) {
      throw const AuthException(
        'Signed in, but the server did not return a session. '
        'Check your inbox if email verification is enabled.',
      );
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final trimmed = email.trim();
    final result = await _post('/sign-up/email', {
      // Better Auth requires a display name; the form only asks for an email.
      'name': trimmed.split('@').first,
      'email': trimmed,
      'password': password,
    });

    // With email verification on, no session is issued yet. The account exists
    // and the UI already tells the user to check their inbox.
    await _acceptSession(result.data, result.cookie);
  }

  @override
  Future<void> signOut() async {
    final cookie = _cookie;
    if (cookie != null) {
      try {
        await _dio.post<dynamic>(
          '${_config.authUrl}/sign-out',
          options: Options(headers: _authHeaders(cookie)),
        );
      } catch (_) {
        // Signing out must work offline; the local session is cleared below.
      }
    }
    await invalidateSession();
  }

  /// Clears the local session without a network call.
  ///
  /// Used on sign-out and when the server reports the session is no longer
  /// valid. The wallets stay on disk, so the app remains fully usable.
  @override
  Future<void> invalidateSession() async {
    _cookie = null;
    _jwt = null;
    _jwtExpiry = null;
    _user = null;
    await _store.clear();
    _changes.add(null);
  }

  @override
  Future<String?> currentAccessToken() async {
    await _ready;
    final cookie = _cookie;
    if (cookie == null) return null;

    final cached = _jwt;
    final expiry = _jwtExpiry;
    if (cached != null &&
        expiry != null &&
        expiry.difference(DateTime.now().toUtc()) >
            const Duration(seconds: 60)) {
      return cached;
    }

    try {
      final response = await _dio.get<dynamic>(
        '${_config.authUrl}/token',
        options: Options(headers: _authHeaders(cookie)),
      );
      final body = response.data;
      final token = body is Map ? body['token'] : null;
      if (token is! String || token.isEmpty) return null;
      _jwt = token;
      _jwtExpiry = jwtExpiry(token);
      return token;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        // The session expired or was revoked on another device.
        await invalidateSession();
        return null;
      }
      rethrow;
    }
  }

  /// Saves the session from a sign-in/sign-up response.
  Future<AuthUser?> _acceptSession(
    Map<String, dynamic> body,
    String? setCookie,
  ) async {
    final token = body['token'];
    final userJson = body['user'];
    if (token is! String || userJson is! Map) return null;

    final email = userJson['email'];
    final id = userJson['id'];
    if (email is! String || id is! String) return null;

    // The server issued a signed cookie; that is the only form it accepts back.
    final cookie = setCookie ?? '$neonSessionCookieName=$token';
    final user = AuthUser(id: id, email: email);

    _cookie = cookie;
    _user = user;
    _jwt = null;
    _jwtExpiry = null;
    await _store.write(
      NeonSession(cookie: cookie, userId: id, email: email),
    );
    _changes.add(user);
    return user;
  }

  Future<({Map<String, dynamic> data, String? cookie})> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '${_config.authUrl}$path',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Origin': _config.authOrigin,
          },
        ),
      );
      final data = response.data;
      return (
        data: data is Map<String, dynamic> ? data : <String, dynamic>{},
        cookie: sessionCookieFromSetCookie(response.headers['set-cookie']),
      );
    } on DioException catch (error) {
      throw AuthException(friendlyAuthError(_messageFrom(error)));
    }
  }

  Map<String, String> _authHeaders(String cookie) => {
        'Cookie': cookie,
        'Origin': _config.authOrigin,
      };

  /// Better Auth reports `{ code, message }`; surface the readable part.
  String _messageFrom(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) return message;
    }
    return error.message ?? error.toString();
  }
}
