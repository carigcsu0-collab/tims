import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/supplier_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for suppliers list.
sealed class SuppliersState {
  const SuppliersState();
}

class SuppliersInitial extends SuppliersState {
  const SuppliersInitial();
}

class SuppliersLoading extends SuppliersState {
  const SuppliersLoading();
}

class SuppliersLoaded extends SuppliersState {
  const SuppliersLoaded(this.suppliers, {this.hasMore = false});
  final List<SupplierModel> suppliers;
  final bool hasMore;
}

class SuppliersError extends SuppliersState {
  const SuppliersError(this.message);
  final String message;
}

/// Repository provider for suppliers.
final suppliersRepositoryProvider =
    Provider<CrudRepository<SupplierModel>>((ref) {
  return CrudRepository<SupplierModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.suppliers,
    fromJson: SupplierModel.fromJson,
  );
});

/// Notifier managing suppliers list state.
class SuppliersNotifier extends StateNotifier<SuppliersState> {
  SuppliersNotifier(this._repository) : super(const SuppliersInitial());

  final CrudRepository<SupplierModel> _repository;

  String _search = '';
  int _page = 1;
  List<SupplierModel> _suppliers = [];

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    _page = 1;
    _suppliers = [];
    state = const SuppliersLoading();
    await _load();
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is SuppliersLoaded && !current.hasMore) return;
    _page++;
    await _load(append: true);
  }

  Future<void> _load({bool append = false}) async {
    final result = await _repository.getPaginated(
      page: _page,
      search: _search.isNotEmpty ? _search : null,
    );

    state = result.fold(
      (failure) => SuppliersError(failure.message),
      (response) {
        if (append) {
          _suppliers = [..._suppliers, ...response.data];
        } else {
          _suppliers = response.data;
        }
        return SuppliersLoaded(_suppliers, hasMore: response.hasNext);
      },
    );
  }
}

final suppliersNotifierProvider =
    StateNotifierProvider<SuppliersNotifier, SuppliersState>((ref) {
  return SuppliersNotifier(ref.watch(suppliersRepositoryProvider));
});
