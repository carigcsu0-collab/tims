import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for persisting authentication tokens and sensitive data.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  // Keys
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserRole = 'user_role';
  static const String _keyThemeMode = 'theme_mode';

  /// Saves the access token.
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  /// Retrieves the access token, or null if not set.
  Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  /// Saves the refresh token.
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  /// Retrieves the refresh token.
  Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  /// Clears all stored authentication data.
  Future<void> clearAuth() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserRole);
  }

  /// Saves the theme mode preference.
  Future<void> saveThemeMode(String mode) =>
      _storage.write(key: _keyThemeMode, value: mode);

  /// Retrieves the theme mode preference.
  Future<String?> getThemeMode() => _storage.read(key: _keyThemeMode);

  /// Clears all stored data.
  Future<void> clearAll() => _storage.deleteAll();
}
