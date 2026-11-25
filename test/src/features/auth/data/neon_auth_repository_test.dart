import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/auth/data/neon_auth_repository.dart';

void main() {
  group('sessionCookieFromSetCookie', () {
    test('keeps only the name=value pair', () {
      final cookie = sessionCookieFromSetCookie([
        'other=1; Path=/',
        '$neonSessionCookieName=abc.def; Path=/; HttpOnly; Secure; SameSite=Lax',
      ]);

      expect(cookie, '$neonSessionCookieName=abc.def');
    });

    test('ignores unrelated cookies and empty headers', () {
      expect(sessionCookieFromSetCookie(null), isNull);
      expect(sessionCookieFromSetCookie(const []), isNull);
      expect(sessionCookieFromSetCookie(['theme=dark']), isNull);
    });
  });

  group('jwtExpiry', () {
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

    String tokenWith(Map<String, Object?> payload) {
      return '${encode({'alg': 'EdDSA'})}.${encode(payload)}.signature';
    }

    test('reads the exp claim as UTC', () {
      final expiry = jwtExpiry(tokenWith({'exp': 1795479155}));

      expect(expiry,
          DateTime.fromMillisecondsSinceEpoch(1795479155000, isUtc: true));
    });

    test('returns null for malformed tokens', () {
      expect(jwtExpiry('not-a-jwt'), isNull);
      expect(jwtExpiry(tokenWith({'sub': 'user'})), isNull);
    });
  });
}
