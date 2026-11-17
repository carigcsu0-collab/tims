import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/maintenance_model.dart';
import 'package:tims/features/maintenance/providers/maintenance_provider.dart';
import 'package:tims/features/maintenance/widgets/complete_maintenance_dialog.dart';

/// Detail view for a single maintenance record.
class MaintenanceDetailPage extends ConsumerWidget {
  const MaintenanceDetailPage({super.key, required this.maintenance});

  /// The record as last shown in the list; used until the list has it.
  final MaintenanceModel maintenance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(maintenanceNotifierProvider);
    final matches = state is MaintenanceLoaded
        ? state.items.where((m) => m.id == maintenance.id).toList()
        : const <MaintenanceModel>[];
    final m = matches.isEmpty ? maintenance : matches.first;
    final canComplete = m.status == MaintenanceStatus.scheduled ||
        m.status == MaintenanceStatus.inProgress;

    return Scaffold(
      appBar: AppBar(
        title: Text(m.maintenanceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _delete(context, ref, m),
          ),
        ],
      ),
      body: ListView(
        padding: context.responsivePadding,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.itemName,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadge.fromLabel(m.status.label),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(label: 'Type', value: m.type.label),
          _DetailRow(
            label: 'Scheduled',
            value: DateHelper.formatDate(m.scheduledDate),
          ),
          _DetailRow(
            label: 'Completed',
            value: DateHelper.formatDate(m.completedDate),
          ),
          _DetailRow(label: 'Technician', value: m.technician),
          _DetailRow(
            label: 'Cost',
            value: FormatHelper.currency(m.cost),
          ),
          _DetailRow(
            label: 'Next maintenance',
            value: DateHelper.formatDate(m.nextMaintenanceDate),
          ),
          _DetailRow(label: 'Description', value: m.description),
          _DetailRow(label: 'Findings', value: m.findings),
          _DetailRow(label: 'Recommendations', value: m.recommendations),
          if (canComplete) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showCompleteMaintenanceDialog(context, m),
              icon: const Icon(Icons.check),
              label: const Text('Mark complete'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    MaintenanceModel m,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete maintenance record?'),
        content: Text(
          'Delete ${m.maintenanceNumber}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error =
        await ref.read(maintenanceNotifierProvider.notifier).delete(m.id);
    if (!context.mounted) return;
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Maintenance record deleted');
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final trimmed = value?.trim();
    final text = (trimmed == null || trimmed.isEmpty) ? '-' : trimmed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
