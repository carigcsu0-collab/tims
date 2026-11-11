import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/features/notifications/providers/notifications_provider.dart';

/// Notifications page showing user notifications.
class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state is NotificationsLoaded && state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsNotifierProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Notifications',
                subtitle: 'Stay updated on inventory activities',
                icon: Icons.notifications,
              ),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(NotificationsState state) {
    if (state is NotificationsLoading || state is NotificationsInitial) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is NotificationsError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(notificationsNotifierProvider.notifier).refresh(),
      );
    }
    if (state is NotificationsLoaded) {
      if (state.notifications.isEmpty) {
        return const EmptyState(
          icon: Icons.notifications_none_outlined,
          title: 'No Notifications',
          message: 'You\'re all caught up!',
        );
      }
      return ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final n = state.notifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: n.isRead
                  ? context.colorScheme.surfaceContainerHighest
                  : context.colorScheme.primaryContainer,
              child: Icon(
                Icons.notifications,
                color: n.isRead
                    ? context.colorScheme.onSurfaceVariant
                    : context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              n.title,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '${n.message}\n${DateHelper.timeAgo(n.createdAt)}',
            ),
            isThreeLine: true,
            trailing: StatusBadge.fromLabel(n.type.label),
            onTap: () {
              if (!n.isRead) {
                ref.read(notificationsNotifierProvider.notifier).markAsRead(n.id);
              }
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
