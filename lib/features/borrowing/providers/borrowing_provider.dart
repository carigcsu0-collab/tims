import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/borrowing_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

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

class BorrowingNotifier extends StateNotifier<BorrowingState> {
  BorrowingNotifier(this._repository) : super(const BorrowingInitial());

  final CrudRepository<BorrowingModel> _repository;

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

final borrowingNotifierProvider =
    StateNotifierProvider<BorrowingNotifier, BorrowingState>((ref) {
  return BorrowingNotifier(ref.watch(borrowingRepositoryProvider));
});
