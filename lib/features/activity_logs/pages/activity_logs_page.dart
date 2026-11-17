import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/paginated_response.dart';
import 'package:tims/features/activity_logs/models/activity_log_entry.dart';
import 'package:tims/features/activity_logs/providers/activity_logs_provider.dart';

/// Paginated, read-only list of system activity.
class ActivityLogsPage extends ConsumerStatefulWidget {
  const ActivityLogsPage({super.key});

  @override
  ConsumerState<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends ConsumerState<ActivityLogsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activityLogsNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityLogsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Activity Logs',
                subtitle: 'Recent actions performed in the system',
                icon: Icons.history,
              ),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<PaginatedResponse<ActivityLogEntry>> state,
  ) {
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state.hasError) {
      final error = state.error;
      return ErrorDisplay(
        message: error is Failure ? error.message : '$error',
        onRetry: () =>
            ref.read(activityLogsNotifierProvider.notifier).refresh(),
      );
    }
    final page = state.requireValue;
    if (page.data.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No Activity',
        message: 'No activity has been recorded yet.',
      );
    }
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: page.data.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = page.data[index];
              final title = (entry.description?.isNotEmpty ?? false)
                  ? entry.description!
                  : '${entry.action} ${entry.module}';
              final when = entry.createdAt == null
                  ? ''
                  : ' | ${dateFormat.format(entry.createdAt!.toLocal())}';
              return ListTile(
                title: Text(
                  title,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('${entry.userName}$when'),
                trailing: StatusBadge.fromLabel(entry.action),
              );
            },
          ),
        ),
        _PaginationBar(
          page: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          onPage: (p) =>
              ref.read(activityLogsNotifierProvider.notifier).goToPage(p),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.lastPage,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int lastPage;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$total total', style: context.textTheme.bodySmall),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onPage(page - 1) : null,
          ),
          Text('Page $page of $lastPage'),
          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Icons.chevron_right),
            onPressed: page < lastPage ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
