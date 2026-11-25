/// The signed-in user, reduced to what the UI needs.
///
/// Deliberately not a vendor `User` type: the rest of the app should never
/// depend on a vendor SDK. That is what lets us swap Neon for a FastAPI
/// backend later without touching screens or providers.
class AuthUser {
  const AuthUser({required this.id, required this.email});

  /// Stable backend id. We do not display it; it identifies the account.
  final String id;

  final String email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() => 'AuthUser($email)';
}
