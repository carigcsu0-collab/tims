import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/maintenance_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for maintenance list.
sealed class MaintenanceState {
  const MaintenanceState();
}

class MaintenanceInitial extends MaintenanceState {
  const MaintenanceInitial();
}

class MaintenanceLoading extends MaintenanceState {
  const MaintenanceLoading();
}

class MaintenanceLoaded extends MaintenanceState {
  const MaintenanceLoaded(this.items, {this.hasMore = false});
  final List<MaintenanceModel> items;
  final bool hasMore;
}

class MaintenanceError extends MaintenanceState {
  const MaintenanceError(this.message);
  final String message;
}

final maintenanceRepositoryProvider =
    Provider<CrudRepository<MaintenanceModel>>((ref) {
  return CrudRepository<MaintenanceModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.maintenances,
    fromJson: MaintenanceModel.fromJson,
  );
});

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  MaintenanceNotifier(this._repository) : super(const MaintenanceInitial());

  final CrudRepository<MaintenanceModel> _repository;

  String _search = '';
  int _page = 1;
  List<MaintenanceModel> _items = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _items = [];
    state = const MaintenanceLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is MaintenanceLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => MaintenanceError(failure.message),
      (response) {
        if (append) {
          _items = [..._items, ...response.data];
        } else {
          _items = response.data;
        }
        return MaintenanceLoaded(_items, hasMore: response.hasNext);
      },
    );
  }
}

final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  return MaintenanceNotifier(ref.watch(maintenanceRepositoryProvider));
});
