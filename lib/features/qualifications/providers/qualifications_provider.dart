import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/qualification_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

/// State for the qualifications list.
sealed class QualificationsState {
  const QualificationsState();
}

class QualificationsInitial extends QualificationsState {
  const QualificationsInitial();
}

class QualificationsLoading extends QualificationsState {
  const QualificationsLoading();
}

class QualificationsLoaded extends QualificationsState {
  const QualificationsLoaded(this.qualifications);
  final List<QualificationModel> qualifications;
}

class QualificationsError extends QualificationsState {
  const QualificationsError(this.message);
  final String message;
}

final qualificationsRepositoryProvider =
    Provider<CrudRepository<QualificationModel>>((ref) {
  return CrudRepository<QualificationModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.qualifications,
    fromJson: QualificationModel.fromJson,
  );
});

/// Manages the qualifications list and its create, update and delete actions.
class QualificationsNotifier extends StateNotifier<QualificationsState> {
  QualificationsNotifier(this._repository)
      : super(const QualificationsInitial());

  final CrudRepository<QualificationModel> _repository;

  String _search = '';

  void setSearch(String value) {
    _search = value;
    refresh();
  }

  Future<void> refresh() async {
    state = const QualificationsLoading();
    final result = await _repository.getAll(
      search: _search.isNotEmpty ? _search : null,
    );
    state = result.fold(
      (failure) => QualificationsError(failure.message),
      (items) => QualificationsLoaded(items),
    );
  }

  /// Saves a qualification. Pass [id] to update, or null to create.
  /// Returns an error message on failure, or null on success.
  Future<String?> save({
    int? id,
    required String name,
    required String code,
    String? ncLevel,
    required bool isActive,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'code': code,
      'nc_level': ncLevel,
      'is_active': isActive,
    };
    final result = id == null
        ? await _repository.create(data)
        : await _repository.update(id, data);
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
}

final qualificationsNotifierProvider =
    StateNotifierProvider<QualificationsNotifier, QualificationsState>((ref) {
  return QualificationsNotifier(ref.watch(qualificationsRepositoryProvider));
});
