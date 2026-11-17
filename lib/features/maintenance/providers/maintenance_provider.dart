import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/maintenance_model.dart';
import 'package:tims/core/repositories/base_repository.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// Maps a maintenance JSON payload to [MaintenanceModel].
/// The API returns the item name as a nested `item` relation and casts
/// `cost` as a decimal string, so both are normalised here.
MaintenanceModel parseMaintenance(Map<String, dynamic> json) {
  final item = json['item'];
  return MaintenanceModel.fromJson({
    ...json,
    'item_name': json['item_name'] ??
        (item is Map<String, dynamic> ? item['name'] : null) ??
        '',
    'cost': double.tryParse('${json['cost'] ?? 0}') ?? 0,
  });
}

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
    fromJson: parseMaintenance,
  );
});

/// Inventory items available to link a maintenance record to.
final maintenanceItemOptionsProvider =
    FutureProvider.autoDispose<List<ItemModel>>((ref) async {
  final repository = CrudRepository<ItemModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.items,
    fromJson: ItemModel.fromJson,
  );
  final result = await repository.getPaginated(perPage: 100);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (response) => response.data,
  );
});

class MaintenanceNotifier extends StateNotifier<MaintenanceState>
    with RepositoryErrorHandler {
  MaintenanceNotifier(this._repository, this._apiClient)
      : super(const MaintenanceInitial());

  final CrudRepository<MaintenanceModel> _repository;
  final ApiClient _apiClient;

  String _search = '';
  int _page = 1;
  List<MaintenanceModel> _items = [];

  /// Creates a new maintenance record, then reloads the list.
  /// Returns an error message on failure, or null on success.
  Future<String?> save(Map<String, dynamic> data) async {
    final result = await _repository.create(data);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Deletes a record and removes it from the loaded list.
  /// Returns an error message on failure, or null on success.
  Future<String?> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure.message, (_) {
      _replaceItems(_items.where((m) => m.id != id).toList());
      return null;
    });
  }

  /// Marks a scheduled or in-progress record as completed. The updated
  /// record replaces the existing one in the loaded list.
  /// Returns an error message on failure, or null on success.
  Future<String?> complete(
    int id, {
    String? findings,
    String? recommendations,
    double? cost,
    DateTime? nextMaintenanceDate,
  }) async {
    final result = await guard(() async {
      final response = await _apiClient.post(
        '${ApiEndpoints.maintenanceById(id)}/complete',
        data: {
          'findings': findings,
          'recommendations': recommendations,
          'cost': ?cost,
          'next_maintenance_date':
              nextMaintenanceDate != null ? _isoDate(nextMaintenanceDate) : null,
        },
      );
      return parseMaintenance(response.data as Map<String, dynamic>);
    });
    return result.fold((failure) => failure.message, (updated) {
      _replaceItems([for (final m in _items) m.id == id ? updated : m]);
      return null;
    });
  }

  void _replaceItems(List<MaintenanceModel> items) {
    _items = items;
    final current = state;
    final hasMore = current is MaintenanceLoaded && current.hasMore;
    state = MaintenanceLoaded(_items, hasMore: hasMore);
  }

  static String _isoDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

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
  return MaintenanceNotifier(
    ref.watch(maintenanceRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});
