import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/disabled_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// The single place the app chooses an auth backend.
///
/// Defaults to a disabled backend so tests and unconfigured builds never touch
/// the network. `main.dart` overrides it when Supabase keys are present.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return const DisabledAuthRepository();
});

/// The current user, as a stream so any screen can react to sign-in/out.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Thin wrapper over [AuthRepository] used by the sign-in screen.
///
/// It exists so the screen does not need to know which backend is active, and
/// so future concerns (analytics, "signing in" telemetry) have one home.
class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  bool get isAvailable => _repository.isAvailable;

  Future<void> signIn({required String email, required String password}) {
    return _repository.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _repository.signUp(email: email, password: password);
  }

  Future<void> signOut() => _repository.signOut();
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
