import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/auth_service.dart';
import 'package:tims/app/services/providers.dart';
import 'package:tims/core/exceptions/failure.dart';

/// State for the auth flow.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}

/// Notifier managing authentication state.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthInitial());

  final AuthService _authService;

  /// Attempts to restore a previous session.
  Future<void> restoreSession() async {
    state = const AuthLoading();
    final success = await _authService.restoreSession();
    if (success) {
      state = const AuthAuthenticated();
    } else {
      state = const AuthInitial();
    }
  }

  /// Logs in with [email] and [password].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    final result = await _authService.login(email: email, password: password);
    state = result.fold(
      (failure) => AuthError(failure.message),
      (_) => const AuthAuthenticated(),
    );
  }

  /// Registers a new user.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? position,
  }) async {
    state = const AuthLoading();
    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phone: phone,
      position: position,
    );
    state = result.fold(
      (failure) => AuthError(failure.message),
      (_) => const AuthAuthenticated(),
    );
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _authService.logout();
    state = const AuthInitial();
  }

  /// Requests a password reset link.
  Future<Failure?> forgotPassword(String email) async {
    final result = await _authService.forgotPassword(email);
    return result.fold(
      (failure) => failure,
      (_) => null,
    );
  }
}

/// Provider for [AuthNotifier].
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authServiceProvider));
});
