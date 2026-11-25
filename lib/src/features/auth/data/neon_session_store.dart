import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The bits of a Neon Auth session needed to act as the user again.
class NeonSession {
  const NeonSession({
    required this.cookie,
    required this.userId,
    required this.email,
  });

  /// The whole `__Secure-neon-auth.session_token=...` pair.
  ///
  /// Neon Auth does not accept a bearer session token, only this signed cookie,
  /// so the signature is part of what must be persisted.
  final String cookie;
  final String userId;
  final String email;

  Map<String, dynamic> toJson() => {
        'cookie': cookie,
        'userId': userId,
        'email': email,
      };

  static NeonSession? fromJson(Object? json) {
    if (json is! Map) return null;
    final cookie = json['cookie'];
    final userId = json['userId'];
    final email = json['email'];
    if (cookie is! String || userId is! String || email is! String) {
      return null;
    }
    return NeonSession(cookie: cookie, userId: userId, email: email);
  }
}

/// Stores the Neon session in the OS keyring.
///
/// Why not a preferences file? A session cookie can act as the user for days.
/// On Linux, `flutter_secure_storage` talks to the Secret Service (GNOME
/// Keyring / KWallet), which needs `libsecret` installed.
///
/// If the keyring is missing, writes fail. Rather than crash at startup, this
/// class falls back to memory for the current run: the user can still sign in,
/// but has to sign in again after a restart.
class NeonSessionStore {
  NeonSessionStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'walletwave.neon.session';

  final FlutterSecureStorage _storage;

  /// Used when the keyring is unavailable.
  NeonSession? _memory;

  bool _warned = false;

  Future<NeonSession?> read() async {
    if (_memory != null) return _memory;
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      _memory = NeonSession.fromJson(jsonDecode(raw));
      return _memory;
    } catch (error) {
      _warnAboutKeyring();
      return null;
    }
  }

  Future<void> write(NeonSession session) async {
    _memory = session;
    try {
      await _storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (_) {
      _warnAboutKeyring();
    }
  }

  Future<void> clear() async {
    _memory = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      _warnAboutKeyring();
    }
  }

  void _warnAboutKeyring() {
    if (_warned) return;
    _warned = true;
    debugPrint(
      'Secure storage is unavailable, so the session is kept in memory only. '
      'On Linux install libsecret and run a keyring service (for example '
      'gnome-keyring) to stay signed in between launches.',
    );
  }
}
