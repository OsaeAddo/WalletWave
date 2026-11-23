/// A sign-in failure with a message that is safe to show to a user.
///
/// Backend auth errors are written for developers ("invalid_grant",
/// "Email not confirmed"). Showing those raw is confusing, so repositories
/// translate them into this type before the UI ever sees them.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Cloud sync is optional. When the app is built without Supabase keys, this
/// is thrown if a user tries to sign in, and the UI shows a setup hint instead
/// of a crash.
class AuthUnavailableException extends AuthException {
  const AuthUnavailableException()
      : super(
          'Cloud sign-in is not configured in this build. '
          'The app still works offline.',
        );
}

/// Turns a raw backend message into plain language.
///
/// Kept as a free function so it is trivial to unit test without any network
/// or SDK in the picture.
String friendlyAuthError(String raw) {
  final text = raw.toLowerCase();

  if (text.contains('invalid login credentials')) {
    return 'Email or password is incorrect.';
  }
  if (text.contains('user already registered') ||
      text.contains('already exists')) {
    return 'That email already has an account. Sign in instead.';
  }
  if (text.contains('email not confirmed')) {
    return 'Check your inbox and confirm your email, then sign in.';
  }
  if (text.contains('password should be') ||
      text.contains('weak password') ||
      text.contains('password is too short')) {
    return 'Use a password with at least 6 characters.';
  }
  if (text.contains('rate limit') || text.contains('too many requests')) {
    return 'Too many attempts. Wait a minute and try again.';
  }
  if (text.contains('socket') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('failed host lookup')) {
    return 'Could not reach the sign-in service. Check your connection.';
  }
  if (text.contains('invalid email') || text.contains('email address')) {
    return 'Enter a valid email address.';
  }

  // Unknown: show the original text rather than a useless generic message.
  return raw;
}
