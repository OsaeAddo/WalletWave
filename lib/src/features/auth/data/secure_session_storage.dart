import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Stores the Supabase session (access + refresh token) in the OS keyring.
///
/// Why not the default shared preferences file? A refresh token is a password
/// equivalent: anyone who reads the file can act as the user. On Linux,
/// `flutter_secure_storage` talks to the Secret Service (GNOME Keyring /
/// KWallet), which requires `libsecret` to be installed.
///
/// If the keyring is missing, writes fail. Rather than crash at startup, this
/// class falls back to memory for the current run: the user can still sign in,
/// but has to sign in again after a restart.
class SecureSessionStorage implements LocalStorage {
  SecureSessionStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'walletwave.supabase.session';

  final FlutterSecureStorage _storage;

  /// Used when the keyring is unavailable.
  String? _memorySession;

  /// Logged once so the terminal explains why sessions do not persist.
  bool _warned = false;

  @override
  Future<void> initialize() async {
    // Nothing to warm up; the plugin opens the keyring on first use.
  }

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _storage.read(key: _sessionKey) ?? _memorySession;
    } catch (_) {
      _warnAboutKeyring();
      return _memorySession;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _memorySession = persistSessionString;
    try {
      await _storage.write(key: _sessionKey, value: persistSessionString);
    } catch (_) {
      _warnAboutKeyring();
    }
  }

  @override
  Future<void> removePersistedSession() async {
    _memorySession = null;
    try {
      await _storage.delete(key: _sessionKey);
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
