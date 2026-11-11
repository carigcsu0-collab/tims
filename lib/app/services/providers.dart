import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/auth_service.dart';
import 'package:tims/app/services/preferences_service.dart';
import 'package:tims/app/services/secure_storage_service.dart';
import 'package:tims/app/services/token_container.dart';
import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/repositories/auth_repository.dart';
import 'package:tims/core/repositories/dashboard_repository.dart';

// --- Infrastructure Providers ---

/// Provides the [SecureStorageService] singleton.
final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provides the [PreferencesService] as an async provider.
final preferencesProvider =
    FutureProvider<PreferencesService>((ref) async {
  return PreferencesService.create();
});

/// Mutable token holder that breaks the dependency cycle between
/// [apiClientProvider] and [authServiceProvider].
/// The [AuthService] updates this container when tokens change.
final tokenContainerProvider = Provider<TokenContainer>((ref) {
  return TokenContainer();
});

/// Provides the [ApiClient] singleton, wired with the auth token provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  final container = ref.watch(tokenContainerProvider);
  return ApiClient.create(tokenProvider: () => container.token);
});

// --- Repository Providers ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(apiClient: ref.watch(apiClientProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(apiClient: ref.watch(apiClientProvider));
});

// --- Service Providers ---

/// Provides the [AuthService] singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  final container = ref.watch(tokenContainerProvider);
  return AuthService(
    authRepository: ref.watch(authRepositoryProvider),
    secureStorage: ref.watch(secureStorageProvider),
    tokenContainer: container,
  );
});
