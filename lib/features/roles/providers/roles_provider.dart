import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/repositories/base_repository.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/roles/models/role_models.dart';

const _rolesEndpoint = '/roles';
const _permissionsEndpoint = '/permissions';

final rolesRepositoryProvider = Provider<CrudRepository<RoleModel>>((ref) {
  return CrudRepository<RoleModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: _rolesEndpoint,
    fromJson: RoleModel.fromJson,
  );
});

final permissionsRepositoryProvider =
    Provider<CrudRepository<PermissionModel>>((ref) {
  return CrudRepository<PermissionModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: _permissionsEndpoint,
    fromJson: PermissionModel.fromJson,
  );
});

/// All roles defined by the backend.
final rolesProvider = FutureProvider<List<RoleModel>>((ref) async {
  final result = await ref.watch(rolesRepositoryProvider).getAll();
  return result.fold<List<RoleModel>>((failure) => throw failure, (roles) => roles);
});

/// All permissions defined by the backend.
final permissionsProvider = FutureProvider<List<PermissionModel>>((ref) async {
  final result = await ref.watch(permissionsRepositoryProvider).getAll();
  return result.fold<List<PermissionModel>>(
      (failure) => throw failure, (permissions) => permissions);
});

/// Reads GET /roles/{role}/permissions. Its response is an object, not a list,
/// so it cannot go through [CrudRepository].
class RolePermissionsRepository with RepositoryErrorHandler {
  RolePermissionsRepository(this._api);

  final ApiClient _api;

  Future<Result<List<String>>> fetch(String role) => guard(() async {
        final response = await _api.get('$_rolesEndpoint/$role/permissions');
        final data = response.data as Map<String, dynamic>;
        return (data['permissions'] as List).cast<String>();
      });
}

/// Permission names granted to the given role name. May contain '*' for all.
final rolePermissionsProvider =
    FutureProvider.family<List<String>, String>((ref, role) async {
  final repository = RolePermissionsRepository(ref.watch(apiClientProvider));
  final result = await repository.fetch(role);
  return result.fold<List<String>>((failure) => throw failure, (names) => names);
});
