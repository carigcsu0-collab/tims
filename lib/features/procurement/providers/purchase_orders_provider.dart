import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/purchase_order_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for purchase orders.
sealed class PurchaseOrdersState {
  const PurchaseOrdersState();
}

class PurchaseOrdersInitial extends PurchaseOrdersState {
  const PurchaseOrdersInitial();
}

class PurchaseOrdersLoading extends PurchaseOrdersState {
  const PurchaseOrdersLoading();
}

class PurchaseOrdersLoaded extends PurchaseOrdersState {
  const PurchaseOrdersLoaded(this.items, {this.hasMore = false});
  final List<PurchaseOrderModel> items;
  final bool hasMore;
}

class PurchaseOrdersError extends PurchaseOrdersState {
  const PurchaseOrdersError(this.message);
  final String message;
}

/// The API nests the item name under `item.name` instead of `item_name`.
PurchaseOrderModel _purchaseOrderFromJson(Map<String, dynamic> json) {
  final rawItems = json['items'];
  if (rawItems is! List) return PurchaseOrderModel.fromJson(json);
  final items = rawItems.map((e) {
    final map = Map<String, dynamic>.from(e as Map);
    final nested = map['item'];
    map['item_name'] ??=
        nested is Map ? (nested['name'] as String? ?? '') : '';
    return map;
  }).toList();
  return PurchaseOrderModel.fromJson({...json, 'items': items});
}

final purchaseOrdersRepositoryProvider =
    Provider<CrudRepository<PurchaseOrderModel>>((ref) {
  return CrudRepository<PurchaseOrderModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.purchaseOrders,
    fromJson: _purchaseOrderFromJson,
  );
});

class PurchaseOrdersNotifier extends StateNotifier<PurchaseOrdersState> {
  PurchaseOrdersNotifier(this._repository)
      : super(const PurchaseOrdersInitial());

  final CrudRepository<PurchaseOrderModel> _repository;

  String _search = '';
  int _page = 1;
  List<PurchaseOrderModel> _items = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _items = [];
    state = const PurchaseOrdersLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is PurchaseOrdersLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => PurchaseOrdersError(failure.message),
      (response) {
        if (append) {
          _items = [..._items, ...response.data];
        } else {
          _items = response.data;
        }
        return PurchaseOrdersLoaded(_items, hasMore: response.hasNext);
      },
    );
  }

  /// Creates a purchase order from a payload matching the API's store rules.
  /// Returns an error message on failure, or null on success.
  Future<String?> create(Map<String, dynamic> data) async {
    final result = await _repository.create(data);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Changes the status of a purchase order.
  /// Returns an error message on failure, or null on success.
  Future<String?> updateStatus(int id, PurchaseOrderStatus status) async {
    final result = await _repository.update(id, {'status': status.name});
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Deletes a purchase order.
  /// Returns an error message on failure, or null on success.
  Future<String?> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Fetches the latest copy of a purchase order, or null on failure.
  Future<PurchaseOrderModel?> fetchById(int id) async {
    final result = await _repository.getById(id);
    return result.fold((_) => null, (po) => po);
  }
}

final purchaseOrdersNotifierProvider =
    StateNotifierProvider<PurchaseOrdersNotifier, PurchaseOrdersState>((ref) {
  return PurchaseOrdersNotifier(
      ref.watch(purchaseOrdersRepositoryProvider));
});
