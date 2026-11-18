import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/qualification_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for items list.
sealed class ItemsState {
  const ItemsState();
}

class ItemsInitial extends ItemsState {
  const ItemsInitial();
}

class ItemsLoading extends ItemsState {
  const ItemsLoading();
}

class ItemsLoaded extends ItemsState {
  const ItemsLoaded(this.items, {this.hasMore = false});
  final List<ItemModel> items;
  final bool hasMore;
}

class ItemsError extends ItemsState {
  const ItemsError(this.message);
  final String message;
}

/// Repository provider for items.
final itemsRepositoryProvider = Provider<CrudRepository<ItemModel>>((ref) {
  return CrudRepository<ItemModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.items,
    fromJson: ItemModel.fromJson,
  );
});

/// Notifier managing the items list state.
class ItemsNotifier extends StateNotifier<ItemsState> {
  ItemsNotifier(this._repository) : super(const ItemsInitial());

  final CrudRepository<ItemModel> _repository;

  String _search = '';
  String? _type;
  String? _condition;
  int? _qualificationId;
  bool _lowStockOnly = false;
  int _page = 1;
  List<ItemModel> _items = [];

  String? get typeFilter => _type;
  String? get conditionFilter => _condition;
  int? get qualificationFilter => _qualificationId;
  bool get lowStockOnly => _lowStockOnly;

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  void setFilters({
    String? type,
    String? condition,
    int? qualificationId,
    bool lowStockOnly = false,
  }) {
    _type = type;
    _condition = condition;
    _qualificationId = qualificationId;
    _lowStockOnly = lowStockOnly;
    refresh();
  }

  /// Creates (or updates when [id] is given) an item, then reloads the list.
  Future<String?> save(Map<String, dynamic> data, {int? id}) async {
    final result = id == null
        ? await _repository.create(data)
        : await _repository.update(id, data);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Deletes an item and reloads the list. Returns an error message on failure.
  Future<String?> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<void> refresh() async {
    _page = 1;
    _items = [];
    state = const ItemsLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! ItemsLoaded || !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
      filters: {
        if (_type != null) 'type': _type,
        if (_condition != null) 'condition': _condition,
        if (_qualificationId != null) 'qualification_id': _qualificationId,
        if (_lowStockOnly) 'low_stock_only': 1,
      },
    );

    state = result.fold(
      (failure) => ItemsError(failure.message),
      (response) {
        if (append) {
          _items = [..._items, ...response.data];
        } else {
          _items = response.data;
        }
        return ItemsLoaded(_items, hasMore: response.hasNext);
      },
    );
  }
}

final itemsNotifierProvider =
    StateNotifierProvider<ItemsNotifier, ItemsState>((ref) {
  return ItemsNotifier(ref.watch(itemsRepositoryProvider));
});

/// Active TVET qualifications used for filters and forms.
final qualificationsProvider =
    FutureProvider<List<QualificationModel>>((ref) async {
  final repo = CrudRepository<QualificationModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.qualifications,
    fromJson: QualificationModel.fromJson,
  );
  final result = await repo.getAll(filters: {'active_only': 1, 'per_page': 200});
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});
