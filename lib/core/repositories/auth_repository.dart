import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/models/auth_token_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/core/repositories/base_repository.dart';

/// Repository handling authentication operations.
class AuthRepository with RepositoryErrorHandler {
  AuthRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Authenticates a user with [email] and [password].
  Future<Result<AuthTokenModel>> login({
    required String email,
    required String password,
  }) =>
      guard(() async {
        final response = await _api.post(
          ApiEndpoints.login,
          data: {'email': email, 'password': password},
        );
        return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
      });

  /// Registers a new user.
  Future<Result<AuthTokenModel>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? position,
  }) =>
      guard(() async {
        final response = await _api.post(
          ApiEndpoints.register,
          data: {
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': passwordConfirmation,
            'phone': ?phone,
            'position': ?position,
          },
        );
        return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
      });

  /// Logs out the current user (invalidates token server-side).
  Future<Result<bool>> logout() =>
      guard(() async {
        await _api.post(ApiEndpoints.logout);
        return true;
      });

  /// Fetches the currently authenticated user.
  Future<Result<UserModel>> currentUser() =>
      guard(() async {
        final response = await _api.get(ApiEndpoints.currentUser);
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      });

  /// Requests a password reset link for [email].
  Future<Result<bool>> forgotPassword(String email) =>
      guard(() async {
        await _api.post(
          ApiEndpoints.forgotPassword,
          data: {'email': email},
        );
        return true;
      });

  /// Resets the password using a [token].
  Future<Result<bool>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) =>
      guard(() async {
        await _api.post(
          ApiEndpoints.resetPassword,
          data: {
            'email': email,
            'token': token,
            'password': password,
            'password_confirmation': passwordConfirmation,
          },
        );
        return true;
      });

  /// Refreshes the access token.
  Future<Result<AuthTokenModel>> refreshToken(String refreshToken) =>
      guard(() async {
        final response = await _api.post(
          ApiEndpoints.refreshToken,
          data: {'refresh_token': refreshToken},
        );
        return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
      });
}
