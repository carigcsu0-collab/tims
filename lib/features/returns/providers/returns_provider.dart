import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/return_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/items/providers/items_provider.dart';

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

/// Detail of a return record, including related names from the API.
class ReturnDetail {
  const ReturnDetail({
    required this.record,
    this.itemName,
    this.returnedByName,
    this.borrowNumber,
  });

  final ReturnModel record;
  final String? itemName;
  final String? returnedByName;
  final String? borrowNumber;
}

/// Options used by the return form pickers.
class ReturnFormOptions {
  const ReturnFormOptions({
    required this.items,
    required this.users,
    this.currentUserId,
  });

  final List<ItemModel> items;
  final List<UserModel> users;
  final int? currentUserId;
}

final returnDetailProvider =
    FutureProvider.autoDispose.family<ReturnDetail, int>((ref, id) async {
  final response =
      await ref.watch(apiClientProvider).get('${ApiEndpoints.returns}/$id');
  final json = response.data as Map<String, dynamic>;
  final item = json['item'] as Map<String, dynamic>?;
  final returnedBy = json['returnedBy'] as Map<String, dynamic>?;
  final borrowing = json['borrowing'] as Map<String, dynamic>?;
  return ReturnDetail(
    record: ReturnModel.fromJson(json),
    itemName: item?['name'] as String?,
    returnedByName: returnedBy?['name'] as String?,
    borrowNumber: borrowing?['borrow_number'] as String?,
  );
});

final returnFormOptionsProvider =
    FutureProvider.autoDispose<ReturnFormOptions>((ref) async {
  final itemsResult =
      await ref.watch(itemsRepositoryProvider).getPaginated(perPage: 100);
  final items = itemsResult.fold(
    (failure) => throw Exception(failure.message),
    (response) => response.data,
  );

  final usersRepo = CrudRepository<UserModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.users,
    fromJson: UserModel.fromJson,
  );
  final usersResult = await usersRepo.getPaginated(perPage: 200);
  final users = usersResult.fold(
    (failure) => throw Exception(failure.message),
    (response) => response.data,
  );

  final meResult = await ref.watch(authRepositoryProvider).currentUser();
  final currentUserId = meResult.fold((_) => null, (user) => user.id);

  return ReturnFormOptions(
    items: items,
    users: users,
    currentUserId: currentUserId,
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

  /// Creates a return record. Returns an error message on failure, or null on success.
  Future<String?> create(Map<String, dynamic> data) async {
    final result = await _repository.create(data);
    return result.fold((failure) => failure.message, (_) {
      refresh();
      return null;
    });
  }

  /// Updates condition and notes of a return record.
  /// Returns an error message on failure, or null on success.
  Future<String?> update(int id, Map<String, dynamic> data) async {
    final result = await _repository.update(id, data);
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
