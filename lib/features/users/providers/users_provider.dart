import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/models/paginated_response.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/users/models/managed_user.dart';

const _usersEndpoint = '/users';

/// Repository provider for user accounts.
final usersRepositoryProvider = Provider<CrudRepository<ManagedUser>>((ref) {
  return CrudRepository<ManagedUser>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: _usersEndpoint,
    fromJson: ManagedUser.fromJson,
  );
});

/// Notifier managing the paginated user list.
class UsersNotifier
    extends StateNotifier<AsyncValue<PaginatedResponse<ManagedUser>>> {
  UsersNotifier(this._repository) : super(AsyncValue.loading());

  final CrudRepository<ManagedUser> _repository;

  static const _perPage = 15;
  String _search = '';
  int _page = 1;

  void setSearch(String value) {
    _search = value;
    _page = 1;
    refresh();
  }

  void goToPage(int page) {
    _page = page;
    refresh();
  }

  Future<void> refresh() async {
    state = AsyncValue.loading();
    final result = await _repository.getPaginated(
      page: _page,
      perPage: _perPage,
      search: _search,
    );
    state = result.fold<AsyncValue<PaginatedResponse<ManagedUser>>>(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (users) => AsyncValue.data(users),
    );
  }

  /// Saves a user. Pass [id] to update, or null to create.
  /// Returns an error message on failure, or null on success.
  Future<String?> save({
    int? id,
    required Map<String, dynamic> data,
  }) async {
    final result = id == null
        ? await _repository.create(data)
        : await _repository.update(id, data);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Deletes a user. Returns an error message on failure, or null on success.
  Future<String?> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final usersNotifierProvider = StateNotifierProvider<UsersNotifier,
    AsyncValue<PaginatedResponse<ManagedUser>>>((ref) {
  return UsersNotifier(ref.watch(usersRepositoryProvider));
});
