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

final purchaseOrdersRepositoryProvider =
    Provider<CrudRepository<PurchaseOrderModel>>((ref) {
  return CrudRepository<PurchaseOrderModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.purchaseOrders,
    fromJson: PurchaseOrderModel.fromJson,
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
}

final purchaseOrdersNotifierProvider =
    StateNotifierProvider<PurchaseOrdersNotifier, PurchaseOrdersState>((ref) {
  return PurchaseOrdersNotifier(
      ref.watch(purchaseOrdersRepositoryProvider));
});
