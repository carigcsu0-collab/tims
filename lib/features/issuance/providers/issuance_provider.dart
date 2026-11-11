import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/issuance_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

sealed class IssuanceState {
  const IssuanceState();
}

class IssuanceInitial extends IssuanceState {
  const IssuanceInitial();
}

class IssuanceLoading extends IssuanceState {
  const IssuanceLoading();
}

class IssuanceLoaded extends IssuanceState {
  const IssuanceLoaded(this.issuances, {this.hasMore = false});
  final List<IssuanceModel> issuances;
  final bool hasMore;
}

class IssuanceError extends IssuanceState {
  const IssuanceError(this.message);
  final String message;
}

final issuanceRepositoryProvider =
    Provider<CrudRepository<IssuanceModel>>((ref) {
  return CrudRepository<IssuanceModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.issuances,
    fromJson: IssuanceModel.fromJson,
  );
});

class IssuanceNotifier extends StateNotifier<IssuanceState> {
  IssuanceNotifier(this._repository) : super(const IssuanceInitial());

  final CrudRepository<IssuanceModel> _repository;

  String _search = '';
  int _page = 1;
  List<IssuanceModel> _issuances = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _issuances = [];
    state = const IssuanceLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is IssuanceLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => IssuanceError(failure.message),
      (response) {
        if (append) {
          _issuances = [..._issuances, ...response.data];
        } else {
          _issuances = response.data;
        }
        return IssuanceLoaded(_issuances, hasMore: response.hasNext);
      },
    );
  }
}

final issuanceNotifierProvider =
    StateNotifierProvider<IssuanceNotifier, IssuanceState>((ref) {
  return IssuanceNotifier(ref.watch(issuanceRepositoryProvider));
});
