import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/return_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

sealed class ReturnsState {
  const ReturnsState();
}

class ReturnsInitial extends ReturnsState {
  const ReturnsInitial();
}

class ReturnsLoading extends ReturnsState {
  const ReturnsLoading();
}

class ReturnsLoaded extends ReturnsState {
  const ReturnsLoaded(this.returns, {this.hasMore = false});
  final List<ReturnModel> returns;
  final bool hasMore;
}

class ReturnsError extends ReturnsState {
  const ReturnsError(this.message);
  final String message;
}

final returnsRepositoryProvider =
    Provider<CrudRepository<ReturnModel>>((ref) {
  return CrudRepository<ReturnModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.returns,
    fromJson: ReturnModel.fromJson,
  );
});

class ReturnsNotifier extends StateNotifier<ReturnsState> {
  ReturnsNotifier(this._repository) : super(const ReturnsInitial());

  final CrudRepository<ReturnModel> _repository;

  String _search = '';
  int _page = 1;
  List<ReturnModel> _returns = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _returns = [];
    state = const ReturnsLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is ReturnsLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => ReturnsError(failure.message),
      (response) {
        if (append) {
          _returns = [..._returns, ...response.data];
        } else {
          _returns = response.data;
        }
        return ReturnsLoaded(_returns, hasMore: response.hasNext);
      },
    );
  }
}

final returnsNotifierProvider =
    StateNotifierProvider<ReturnsNotifier, ReturnsState>((ref) {
  return ReturnsNotifier(ref.watch(returnsRepositoryProvider));
});
