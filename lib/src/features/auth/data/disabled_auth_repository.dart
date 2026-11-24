import '../domain/auth_error.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// Used when the app was built without Neon backend settings.
///
/// The market and portfolio features work fully offline, so a missing backend
/// must not be a startup crash. This repository reports "signed out forever"
/// and explains the situation if someone taps Sign in.
class DisabledAuthRepository implements AuthRepository {
  const DisabledAuthRepository();

  @override
  bool get isAvailable => false;

  @override
  AuthUser? get currentUser => null;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthUnavailableException();
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    throw const AuthUnavailableException();
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> invalidateSession() async {}

  @override
  Future<String?> currentAccessToken() async => null;
}
