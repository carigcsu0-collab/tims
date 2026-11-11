import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/category_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for categories list.
sealed class CategoriesState {
  const CategoriesState();
}

class CategoriesInitial extends CategoriesState {
  const CategoriesInitial();
}

class CategoriesLoading extends CategoriesState {
  const CategoriesLoading();
}

class CategoriesLoaded extends CategoriesState {
  const CategoriesLoaded(this.categories);
  final List<CategoryModel> categories;
}

class CategoriesError extends CategoriesState {
  const CategoriesError(this.message);
  final String message;
}

/// Repository provider for categories.
final categoriesRepositoryProvider =
    Provider<CrudRepository<CategoryModel>>((ref) {
  return CrudRepository<CategoryModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.categories,
    fromJson: CategoryModel.fromJson,
  );
});

/// Notifier managing categories list state.
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  CategoriesNotifier(this._repository) : super(const CategoriesInitial());

  final CrudRepository<CategoryModel> _repository;

  String _search = '';

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    state = const CategoriesLoading();
    final result = await _repository.getAll(search: _search.isNotEmpty ? _search : null);
    state = result.fold(
      (failure) => CategoriesError(failure.message),
      (categories) => CategoriesLoaded(categories),
    );
  }
}

final categoriesNotifierProvider =
    StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier(ref.watch(categoriesRepositoryProvider));
});
