import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/return_model.dart';
import 'package:tims/features/returns/providers/returns_provider.dart';
import 'package:tims/features/returns/widgets/return_form_dialog.dart';

/// Detail view for a single return record with edit and delete actions.
class ReturnDetailPage extends ConsumerWidget {
  const ReturnDetailPage({super.key, required this.returnId});

  final int returnId;

  Future<void> _delete(BuildContext context, WidgetRef ref, ReturnDetail detail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete return record?'),
        content: Text(
          'Delete "${detail.record.returnNumber}"? This cannot be undone.',
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
    if (!context.mounted) return;
    final error = await ref
        .read(returnsNotifierProvider.notifier)
        .delete(detail.record.id);
    if (!context.mounted) return;
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Return deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(returnDetailProvider(returnId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Detail'),
        actions: [
          detailAsync.maybeWhen(
            data: (detail) => IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showReturnFormDialog(context, record: detail.record),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          detailAsync.maybeWhen(
            data: (detail) => IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: context.colorScheme.error),
              onPressed: () => _delete(context, ref, detail),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: detailAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorDisplay(
              message: 'Could not load return record: $e',
              onRetry: () => ref.invalidate(returnDetailProvider(returnId)),
            ),
            data: (detail) => _buildContent(context, detail),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReturnDetail detail) {
    final r = detail.record;
    return ListView(
      children: [
        PageHeader(
          title: r.returnNumber,
          subtitle: 'Returned item details',
          icon: Icons.undo,
        ),
        const SizedBox(height: 16),
        _infoRow(context, 'Item', detail.itemName ?? '#${r.itemId}'),
        _infoRow(context, 'Quantity', '${r.quantity}'),
        _infoRow(context, 'Return date', r.returnDate),
        _infoRow(context, 'Returned by', detail.returnedByName ?? '#${r.returnedBy}'),
        _infoRow(context, 'Borrow number', detail.borrowNumber ?? '-'),
        _infoRow(context, 'Condition', r.condition?.label ?? '-'),
        _infoRow(context, 'Notes', (r.notes == null || r.notes!.isEmpty) ? '-' : r.notes!),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: context.textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
