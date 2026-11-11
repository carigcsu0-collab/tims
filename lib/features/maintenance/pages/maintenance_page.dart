import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/features/maintenance/providers/maintenance_provider.dart';

/// Maintenance page for managing equipment maintenance schedules and records.
class MaintenancePage extends ConsumerStatefulWidget {
  const MaintenancePage({super.key});

  @override
  ConsumerState<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends ConsumerState<MaintenancePage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(maintenanceNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Maintenance')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Maintenance',
                subtitle: 'Schedule and track equipment maintenance',
                icon: Icons.build,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search maintenance records...',
                onChanged: (value) => ref
                    .read(maintenanceNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.showSnackBar('New maintenance record - coming soon'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceState state) {
    if (state is MaintenanceLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is MaintenanceError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(maintenanceNotifierProvider.notifier).refresh(),
      );
    }
    if (state is MaintenanceLoaded) {
      if (state.items.isEmpty) {
        return const EmptyState(
          icon: Icons.build_outlined,
          title: 'No Maintenance Records',
          message: 'Schedule your first maintenance activity.',
        );
      }
      return ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = state.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.build,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              m.maintenanceNumber,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${m.itemName}'),
                Text(
                  'Type: ${m.type.label} | Scheduled: ${DateHelper.formatDate(m.scheduledDate)}',
                ),
                if (m.technician != null)
                  Text('Technician: ${m.technician}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (m.cost > 0)
                  Text(
                    FormatHelper.currency(m.cost),
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 4),
                StatusBadge.fromLabel(m.status.label),
              ],
            ),
            onTap: () => context.showSnackBar(
                'Maintenance detail for ${m.maintenanceNumber} - coming soon'),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
