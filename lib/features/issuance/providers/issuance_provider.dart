import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/issuance_model.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/items/providers/items_provider.dart';

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

final issuanceRepositoryProvider = Provider<CrudRepository<IssuanceModel>>((
  ref,
) {
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

  /// Creates an issuance. Returns an error message on failure, or null on success.
  Future<String?> save({
    required String issuanceNumber,
    required int issuedTo,
    required String issueDate,
    String? purpose,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await _repository.create({
      'issuance_number': issuanceNumber,
      'issued_to': issuedTo,
      'issue_date': issueDate,
      'purpose': purpose,
      'notes': notes,
      'items': items,
    });
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Updates the editable fields of an issuance. Returns an error message on failure.
  Future<String?> update(int id, {String? purpose, String? notes}) async {
    final result = await _repository.update(id, {
      'purpose': purpose,
      'notes': notes,
    });
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
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
    state = result.fold((failure) => IssuanceError(failure.message), (
      response,
    ) {
      if (append) {
        _issuances = [..._issuances, ...response.data];
      } else {
        _issuances = response.data;
      }
      return IssuanceLoaded(_issuances, hasMore: response.hasNext);
    });
  }
}

final issuanceNotifierProvider =
    StateNotifierProvider<IssuanceNotifier, IssuanceState>((ref) {
      return IssuanceNotifier(ref.watch(issuanceRepositoryProvider));
    });

/// Active users that can receive issued items.
final issuanceRecipientsProvider = FutureProvider<List<UserModel>>((ref) async {
  final repo = CrudRepository<UserModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.users,
    fromJson: UserModel.fromJson,
  );
  final result = await repo.getAll(
    filters: {'active_only': 1, 'per_page': 200},
  );
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});

/// Items available for selection on an issuance.
final issuanceItemOptionsProvider = FutureProvider<List<ItemModel>>((
  ref,
) async {
  final result = await ref
      .watch(itemsRepositoryProvider)
      .getAll(filters: {'per_page': 200});
  return result.fold((failure) => throw Exception(failure.message), (v) => v);
});
