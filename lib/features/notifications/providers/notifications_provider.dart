import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/models/notification_model.dart';
import 'package:tims/core/repositories/crud_repository.dart';

sealed class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsLoaded extends NotificationsState {
  const NotificationsLoaded(this.notifications, {this.unreadCount = 0});
  final List<NotificationModel> notifications;
  final int unreadCount;
}

class NotificationsError extends NotificationsState {
  const NotificationsError(this.message);
  final String message;
}

final notificationsRepositoryProvider =
    Provider<CrudRepository<NotificationModel>>((ref) {
  return CrudRepository<NotificationModel>(
    apiClient: ref.watch(apiClientProvider),
    endpoint: ApiEndpoints.notifications,
    fromJson: NotificationModel.fromJson,
  );
});

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(this._repository, this._apiClient)
      : super(const NotificationsInitial());

  final CrudRepository<NotificationModel> _repository;
  final dynamic _apiClient;

  Future<void> refresh() async {
    state = const NotificationsLoading();
    final result = await _repository.getAll();
    state = result.fold(
      (failure) => NotificationsError(failure.message),
      (notifications) {
        final unread = notifications.where((n) => !n.isRead).length;
        return NotificationsLoaded(notifications, unreadCount: unread);
      },
    );
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.post(ApiEndpoints.notificationsMarkAllRead);
      refresh();
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    try {
      await _apiClient.patch('${ApiEndpoints.notifications}/$id');
      refresh();
    } catch (_) {}
  }
}

final notificationsNotifierProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(apiClientProvider),
  );
});
