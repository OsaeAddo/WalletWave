import 'auth_user.dart';

/// The app's only door to authentication.
///
/// Screens and providers depend on this interface, never on a vendor SDK.
/// Swapping to FastAPI later means writing one new implementation and changing
/// one provider override in `main.dart`.
abstract interface class AuthRepository {
  /// Emits the current user first, then every change (sign-in, sign-out,
  /// token refresh). `null` means signed out.
  ///
  /// Emitting immediately matters: without it the UI would show "signed out"
  /// until the second event, and a restored session would flicker.
  Stream<AuthUser?> authStateChanges();

  /// The user right now, or `null`, without waiting for the stream.
  AuthUser? get currentUser;

  /// Whether this build has a working backend at all.
  bool get isAvailable;

  /// Throws [AuthException] with a user-safe message on failure.
  Future<void> signInWithPassword({
    required String email,
    required String password,
  });

  /// Creates an account. May not sign the user in immediately if the backend
  /// requires email confirmation.
  Future<void> signUp({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Drops the local session without contacting the server.
  ///
  /// Called when the backend says the session is no longer valid. Local wallets
  /// stay on disk, so the app keeps working signed out.
  Future<void> invalidateSession();

  /// Bearer token for backend calls (the data API, functions). Returns `null`
  /// when signed out or when the token cannot be refreshed right now.
  Future<String?> currentAccessToken();
}
