import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/exceptions/app_exceptions.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/purchase_request_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/items/providers/items_provider.dart';

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
  PurchaseRequestsNotifier(this._repository, this._api)
      : super(const PurchaseRequestsInitial());

  final CrudRepository<PurchaseRequestModel> _repository;
  final ApiClient _api;

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

  /// Creates a purchase request with [lines] (item id, quantity, unit cost, unit).
  /// Returns an error message on failure, or null on success.
  Future<String?> save({
    required int requestedBy,
    String? purpose,
    String? department,
    required List<Map<String, dynamic>> lines,
  }) async {
    final data = <String, dynamic>{
      'pr_number': _generatePrNumber(),
      'requested_by': requestedBy,
      'purpose': purpose,
      'department': department,
      'items': lines,
    };
    final result = await _repository.create(data);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> delete(int id) async {
    final result = await _repository.delete(id);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Approves a pending purchase request. Returns an error message on failure.
  Future<String?> approve(int id) =>
      _postAction('${ApiEndpoints.purchaseRequests}/$id/approve');

  /// Rejects a pending purchase request with [reason].
  /// Returns an error message on failure.
  Future<String?> reject(int id, String reason) => _postAction(
        '${ApiEndpoints.purchaseRequests}/$id/reject',
        data: {'rejected_reason': reason},
      );

  Future<String?> _postAction(String path, {Map<String, dynamic>? data}) async {
    try {
      await _api.post<dynamic>(path, data: data);
    } on AppException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
    refresh();
    return null;
  }

  String _generatePrNumber() =>
      'PR-${DateFormat('yyyyMMdd-HHmmss-SSS').format(DateTime.now())}';
}

final purchaseRequestsNotifierProvider = StateNotifierProvider<
    PurchaseRequestsNotifier, PurchaseRequestsState>((ref) {
  return PurchaseRequestsNotifier(
    ref.watch(purchaseRequestsRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});

/// Items available to select as purchase request lines.
final purchaseRequestItemOptionsProvider =
    FutureProvider.autoDispose<List<ItemModel>>((ref) async {
  final result =
      await ref.watch(itemsRepositoryProvider).getPaginated(perPage: 100);
  return result.fold(
    (failure) => throw failure.message,
    (response) => response.data,
  );
});
