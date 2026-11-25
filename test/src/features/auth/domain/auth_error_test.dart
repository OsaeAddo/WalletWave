import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/features/auth/domain/auth_error.dart';

void main() {
  test('maps the common auth failures to plain language', () {
    expect(
      friendlyAuthError('Invalid login credentials'),
      'Email or password is incorrect.',
    );
    expect(
      friendlyAuthError('User already registered'),
      'That email already has an account. Sign in instead.',
    );
    expect(
      friendlyAuthError('Email not confirmed'),
      'Check your inbox and confirm your email, then sign in.',
    );
    expect(
      friendlyAuthError('Password should be at least 6 characters.'),
      'Use a password with at least 6 characters.',
    );
    expect(
      friendlyAuthError('email rate limit exceeded'),
      'Too many attempts. Wait a minute and try again.',
    );
    expect(
      friendlyAuthError('SocketException: Failed host lookup'),
      'Could not reach the sign-in service. Check your connection.',
    );
  });

  test('keeps unknown messages instead of hiding them', () {
    expect(
      friendlyAuthError('Something unusual happened'),
      'Something unusual happened',
    );
  });

  test('the unconfigured message explains the app still works', () {
    const error = AuthUnavailableException();
    expect(error.message, contains('not configured'));
    expect(error.message, contains('offline'));
  });
}
