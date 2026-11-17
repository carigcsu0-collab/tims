import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_client.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/models/borrowing_model.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/core/repositories/base_repository.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/items/providers/items_provider.dart';

/// State for borrowing list.
sealed class BorrowingState {
  const BorrowingState();
}

class BorrowingInitial extends BorrowingState {
  const BorrowingInitial();
}

class BorrowingLoading extends BorrowingState {
  const BorrowingLoading();
}

class BorrowingLoaded extends BorrowingState {
  const BorrowingLoaded(this.items, {this.hasMore = false});
  final List<BorrowingModel> items;
  final bool hasMore;
}

class BorrowingError extends BorrowingState {
  const BorrowingError(this.message);
  final String message;
}

final borrowingRepositoryProvider =
    Provider<CrudRepository<BorrowingModel>>((ref) {
  return CrudRepository<BorrowingModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.borrowings,
    fromJson: BorrowingModel.fromJson,
  );
});

/// Workflow actions (approve, reject, return) that are not plain CRUD calls.
class BorrowingActions with RepositoryErrorHandler {
  BorrowingActions(this._api);

  final ApiClient _api;

  Future<Result<bool>> approve(int id) => guard(() async {
        await _api.post('${ApiEndpoints.borrowings}/$id/approve');
        return true;
      });

  Future<Result<bool>> reject(int id) => guard(() async {
        await _api.post('${ApiEndpoints.borrowings}/$id/reject');
        return true;
      });

  Future<Result<bool>> returnItem(
    int id, {
    String? condition,
    String? notes,
  }) =>
      guard(() async {
        await _api.post(
          '${ApiEndpoints.borrowings}/$id/return',
          data: {
            'condition': ?condition,
            'notes': ?notes,
          },
        );
        return true;
      });
}

class BorrowingNotifier extends StateNotifier<BorrowingState> {
  BorrowingNotifier(this._repository, this._actions)
      : super(const BorrowingInitial());

  final CrudRepository<BorrowingModel> _repository;
  final BorrowingActions _actions;

  String _search = '';
  int _page = 1;
  List<BorrowingModel> _items = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _items = [];
    state = const BorrowingLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is BorrowingLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  /// Creates a borrowing request. Returns an error message on failure, or null on success.
  Future<String?> save({
    required int itemId,
    required int borrowerId,
    required DateTime borrowDate,
    DateTime? expectedReturnDate,
    required int quantity,
    String? purpose,
    String? conditionOut,
    String? notes,
  }) async {
    final now = DateTime.now();
    final result = await _repository.create({
      'borrow_number':
          'BRW-${DateHelper.toIsoDate(now).replaceAll('-', '')}-${now.millisecondsSinceEpoch % 1000000}',
      'item_id': itemId,
      'borrower_id': borrowerId,
      'borrow_date': DateHelper.toIsoDate(borrowDate),
      'expected_return_date': expectedReturnDate == null
          ? null
          : DateHelper.toIsoDate(expectedReturnDate),
      'quantity': quantity,
      'purpose': purpose,
      'condition_out': conditionOut,
      'notes': notes,
    });
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Updates the editable fields of a borrowing. Returns an error message on failure, or null on success.
  Future<String?> update(
    int id, {
    DateTime? expectedReturnDate,
    String? purpose,
    String? notes,
  }) async {
    final result = await _repository.update(id, {
      'expected_return_date': expectedReturnDate == null
          ? null
          : DateHelper.toIsoDate(expectedReturnDate),
      'purpose': purpose,
      'notes': notes,
    });
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<String?> delete(int id) => _runAction(() => _repository.delete(id));

  Future<String?> approve(int id) => _runAction(() => _actions.approve(id));

  Future<String?> reject(int id) => _runAction(() => _actions.reject(id));

  Future<String?> returnItem(int id, {String? condition, String? notes}) =>
      _runAction(
        () => _actions.returnItem(id, condition: condition, notes: notes),
      );

  Future<String?> _runAction(Future<Result<bool>> Function() action) async {
    final result = await action();
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => BorrowingError(failure.message),
      (response) {
        if (append) {
          _items = [..._items, ...response.data];
        } else {
          _items = response.data;
        }
        return BorrowingLoaded(_items, hasMore: response.hasNext);
      },
    );
  }
}

final borrowingActionsProvider = Provider<BorrowingActions>((ref) {
  return BorrowingActions(ref.watch(apiClientProvider));
});

final borrowingNotifierProvider =
    StateNotifierProvider<BorrowingNotifier, BorrowingState>((ref) {
  return BorrowingNotifier(
    ref.watch(borrowingRepositoryProvider),
    ref.watch(borrowingActionsProvider),
  );
});

/// Active users that can be selected as borrower.
final borrowerOptionsProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repo = CrudRepository<UserModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.users,
    fromJson: UserModel.fromJson,
  );
  final result =
      await repo.getAll(filters: {'active_only': 1, 'per_page': 200});
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});

/// Items that can be lent out (tools, equipment and assets).
final borrowableItemsProvider =
    FutureProvider.autoDispose<List<ItemModel>>((ref) async {
  final result =
      await ref.watch(itemsRepositoryProvider).getPaginated(perPage: 200);
  return result.fold(
    (failure) => throw Exception(failure.message),
    (page) => page.data
        .where((i) =>
            i.type != ItemType.consumable && i.type != ItemType.material)
        .toList(),
  );
});
