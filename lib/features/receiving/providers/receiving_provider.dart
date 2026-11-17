import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/purchase_order_model.dart';
import 'package:tims/core/models/receiving_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/items/providers/items_provider.dart';
import 'package:tims/features/procurement/providers/purchase_orders_provider.dart';

sealed class ReceivingState {
  const ReceivingState();
}

class ReceivingInitial extends ReceivingState {
  const ReceivingInitial();
}

class ReceivingLoading extends ReceivingState {
  const ReceivingLoading();
}

class ReceivingLoaded extends ReceivingState {
  const ReceivingLoaded(this.receivings, {this.hasMore = false});
  final List<ReceivingModel> receivings;
  final bool hasMore;
}

class ReceivingError extends ReceivingState {
  const ReceivingError(this.message);
  final String message;
}

final receivingRepositoryProvider =
    Provider<CrudRepository<ReceivingModel>>((ref) {
  return CrudRepository<ReceivingModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.receivings,
    fromJson: ReceivingModel.fromJson,
  );
});

class ReceivingNotifier extends StateNotifier<ReceivingState> {
  ReceivingNotifier(this._repository) : super(const ReceivingInitial());

  final CrudRepository<ReceivingModel> _repository;

  String _search = '';
  int _page = 1;
  List<ReceivingModel> _receivings = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _receivings = [];
    state = const ReceivingLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is ReceivingLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => ReceivingError(failure.message),
      (response) {
        if (append) {
          _receivings = [..._receivings, ...response.data];
        } else {
          _receivings = response.data;
        }
        return ReceivingLoaded(_receivings, hasMore: response.hasNext);
      },
    );
  }

  /// Creates a receiving record (stock is increased by the backend).
  /// Returns an error message on failure, or null on success.
  Future<String?> save({
    required String receivingNumber,
    int? purchaseOrderId,
    required String receivedDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await _repository.create({
      'receiving_number': receivingNumber,
      'purchase_order_id': purchaseOrderId,
      'received_date': receivedDate,
      'notes': notes,
      'items': items,
    });
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Deletes a receiving record. Returns an error message on failure, or null on success.
  Future<String?> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }
}

final receivingNotifierProvider =
    StateNotifierProvider<ReceivingNotifier, ReceivingState>((ref) {
  return ReceivingNotifier(ref.watch(receivingRepositoryProvider));
});

/// Items available for selection on a receiving record.
final receivingItemOptionsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final result =
      await ref.watch(itemsRepositoryProvider).getPaginated(perPage: 100);
  return result.fold((failure) => throw Exception(failure.message),
      (response) => response.data);
});

/// Purchase orders that a receiving record can be linked to.
final receivingPurchaseOrderOptionsProvider =
    FutureProvider<List<PurchaseOrderModel>>((ref) async {
  final result = await ref
      .watch(purchaseOrdersRepositoryProvider)
      .getPaginated(perPage: 100);
  return result.fold((failure) => throw Exception(failure.message),
      (response) => response.data);
});
