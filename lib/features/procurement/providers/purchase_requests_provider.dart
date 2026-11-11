import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/purchase_request_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for purchase requests.
sealed class PurchaseRequestsState {
  const PurchaseRequestsState();
}

class PurchaseRequestsInitial extends PurchaseRequestsState {
  const PurchaseRequestsInitial();
}

class PurchaseRequestsLoading extends PurchaseRequestsState {
  const PurchaseRequestsLoading();
}

class PurchaseRequestsLoaded extends PurchaseRequestsState {
  const PurchaseRequestsLoaded(this.items, {this.hasMore = false});
  final List<PurchaseRequestModel> items;
  final bool hasMore;
}

class PurchaseRequestsError extends PurchaseRequestsState {
  const PurchaseRequestsError(this.message);
  final String message;
}

final purchaseRequestsRepositoryProvider =
    Provider<CrudRepository<PurchaseRequestModel>>((ref) {
  return CrudRepository<PurchaseRequestModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.purchaseRequests,
    fromJson: PurchaseRequestModel.fromJson,
  );
});

class PurchaseRequestsNotifier
    extends StateNotifier<PurchaseRequestsState> {
  PurchaseRequestsNotifier(this._repository)
      : super(const PurchaseRequestsInitial());

  final CrudRepository<PurchaseRequestModel> _repository;

  String _search = '';
  int _page = 1;
  List<PurchaseRequestModel> _items = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _items = [];
    state = const PurchaseRequestsLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is PurchaseRequestsLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => PurchaseRequestsError(failure.message),
      (response) {
        if (append) {
          _items = [..._items, ...response.data];
        } else {
          _items = response.data;
        }
        return PurchaseRequestsLoaded(_items, hasMore: response.hasNext);
      },
    );
  }
}

final purchaseRequestsNotifierProvider = StateNotifierProvider<
    PurchaseRequestsNotifier, PurchaseRequestsState>((ref) {
  return PurchaseRequestsNotifier(
      ref.watch(purchaseRequestsRepositoryProvider));
});
