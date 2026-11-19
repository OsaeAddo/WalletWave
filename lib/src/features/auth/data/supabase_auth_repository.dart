// Imported with a prefix because the Supabase SDK has its own `AuthUser` and
// `AuthException` types. Prefixing makes it obvious which one a line means and
// stops future imports from silently picking the vendor type.
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../domain/auth_error.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// [AuthRepository] backed by Supabase's built-in auth service (GoTrue).
///
/// All the hard parts - password hashing, token refresh, email confirmation,
/// rate limiting - happen on Supabase's servers, so this class stays thin.
/// It also has one job the interface demands: translate SDK errors into
/// [AuthException]s with messages a person can understand.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final sb.SupabaseClient _client;

  sb.GoTrueClient get _auth => _client.auth;

  @override
  bool get isAvailable => true;

  @override
  AuthUser? get currentUser => _toDomain(_auth.currentUser);

  @override
  Stream<AuthUser?> authStateChanges() async* {
    // `onAuthStateChange` replays the restored session as its first event.
    yield currentUser;
    yield* _auth.onAuthStateChange.map(
      (state) => _toDomain(state.session?.user),
    );
  }

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email.trim(), password: password);
    } on sb.AuthException catch (error) {
      throw AuthException(friendlyAuthError(error.message));
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signUp(email: email.trim(), password: password);
    } on sb.AuthException catch (error) {
      throw AuthException(friendlyAuthError(error.message));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Local scope clears the session on this device without a server call,
      // so signing out works offline and cannot fail because of a network
      // problem. Other devices keep their own sessions.
      await _auth.signOut(scope: sb.SignOutScope.local);
    } on sb.AuthException catch (error) {
      throw AuthException(friendlyAuthError(error.message));
    }
  }

  @override
  Future<String?> currentAccessToken() async =>
      _auth.currentSession?.accessToken;

  static AuthUser? _toDomain(sb.User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email ?? '');
  }
}
