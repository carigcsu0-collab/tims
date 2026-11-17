import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/models/paginated_response.dart';
import 'package:tims/core/repositories/crud_repository.dart';
import 'package:tims/features/activity_logs/models/activity_log_entry.dart';

const _activityLogsEndpoint = '/activity-logs';

final activityLogsRepositoryProvider =
    Provider<CrudRepository<ActivityLogEntry>>((ref) {
  return CrudRepository<ActivityLogEntry>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: _activityLogsEndpoint,
    fromJson: ActivityLogEntry.fromJson,
  );
});

/// Notifier managing the paginated, read-only activity log.
class ActivityLogsNotifier
    extends StateNotifier<AsyncValue<PaginatedResponse<ActivityLogEntry>>> {
  ActivityLogsNotifier(this._repository)
      : super(AsyncValue.loading());

  final CrudRepository<ActivityLogEntry> _repository;

  static const _perPage = 20;
  int _page = 1;

  void goToPage(int page) {
    _page = page;
    refresh();
  }

  Future<void> refresh() async {
    state = AsyncValue.loading();
    final result =
        await _repository.getPaginated(page: _page, perPage: _perPage);
    state = result.fold<AsyncValue<PaginatedResponse<ActivityLogEntry>>>(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (logs) => AsyncValue.data(logs),
    );
  }
}

final activityLogsNotifierProvider = StateNotifierProvider<ActivityLogsNotifier,
    AsyncValue<PaginatedResponse<ActivityLogEntry>>>((ref) {
  return ActivityLogsNotifier(ref.watch(activityLogsRepositoryProvider));
});
