import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';

import 'package:tims/core/exceptions/app_exceptions.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/models/auth_token_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/core/repositories/auth_repository.dart';
import 'package:tims/app/services/secure_storage_service.dart';
import 'package:tims/app/services/token_container.dart';

/// Central authentication service managing login state, token persistence,
/// and current user session.
class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required SecureStorageService secureStorage,
    required TokenContainer tokenContainer,
  })  : _authRepo = authRepository,
        _secureStorage = secureStorage,
        _tokenContainer = tokenContainer;

  final AuthRepository _authRepo;
  final SecureStorageService _secureStorage;
  final TokenContainer _tokenContainer;

  AuthTokenModel? _currentToken;
  UserModel? _currentUser;

  /// Returns the current access token, or null if not authenticated.
  String? get accessToken => _currentToken?.accessToken;

  void _syncToken() {
    _tokenContainer.token = _currentToken?.accessToken;
  }

  /// Returns the current authenticated user, or null.
  UserModel? get currentUser => _currentUser;

  /// Returns true if a user is currently authenticated.
  bool get isAuthenticated => _currentToken != null;

  /// Attempts to restore a previously stored session on app launch.
  Future<bool> restoreSession() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null || token.isEmpty) return false;

    _currentToken = AuthTokenModel(
      accessToken: token,
      tokenType: 'Bearer',
      user: const UserModel(
        id: 0,
        name: '',
        email: '',
      ),
    );
    _syncToken();

    final result = await _authRepo.currentUser();
    return result.fold(
      (failure) {
        _currentToken = null;
        _syncToken();
        return false;
      },
      (user) {
        _currentUser = user;
        return true;
      },
    );
  }

  /// Authenticates a user with [email] and [password].
  Future<Result<AuthTokenModel>> login({
    required String email,
    required String password,
  }) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return ResultUtils.fromException(
          NetworkException(message: 'No internet connection. Please check your network.'),
        );
      }
    }

    final result = await _authRepo.login(email: email, password: password);

    return result.fold(
      (failure) => Left(failure),
      (token) async {
        _currentToken = token;
        _currentUser = token.user;
        _syncToken();
        await _secureStorage.saveAccessToken(token.accessToken);
        if (token.refreshToken != null) {
          await _secureStorage.saveRefreshToken(token.refreshToken!);
        }
        return Right(token);
      },
    );
  }

  /// Registers a new user.
  Future<Result<AuthTokenModel>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? position,
  }) async {
    final result = await _authRepo.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phone: phone,
      position: position,
    );

    return result.fold(
      (failure) => Left(failure),
      (token) async {
        _currentToken = token;
        _currentUser = token.user;
        _syncToken();
        await _secureStorage.saveAccessToken(token.accessToken);
        if (token.refreshToken != null) {
          await _secureStorage.saveRefreshToken(token.refreshToken!);
        }
        return Right(token);
      },
    );
  }

  /// Logs out the current user and clears stored credentials.
  Future<Result<bool>> logout() async {
    final result = await _authRepo.logout();
    await _secureStorage.clearAuth();
    _currentToken = null;
    _currentUser = null;
    _syncToken();
    return result;
  }

  /// Requests a password reset link.
  Future<Result<bool>> forgotPassword(String email) =>
      _authRepo.forgotPassword(email);

  /// Clears local session without calling the API (used on 401 errors).
  Future<void> clearSession() async {
    await _secureStorage.clearAuth();
    _currentToken = null;
    _currentUser = null;
    _syncToken();
  }
}
