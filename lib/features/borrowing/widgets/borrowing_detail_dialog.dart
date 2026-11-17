import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/models/borrowing_model.dart';
import 'package:tims/features/borrowing/providers/borrowing_provider.dart';

/// Shows the detail dialog for a borrowing with its workflow actions.
Future<void> showBorrowingDetailDialog(
  BuildContext context,
  BorrowingModel borrowing,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => BorrowingDetailDialog(borrowing: borrowing),
  );
}

class BorrowingDetailDialog extends ConsumerStatefulWidget {
  const BorrowingDetailDialog({super.key, required this.borrowing});

  final BorrowingModel borrowing;

  @override
  ConsumerState<BorrowingDetailDialog> createState() =>
      _BorrowingDetailDialogState();
}

class _BorrowingDetailDialogState extends ConsumerState<BorrowingDetailDialog> {
  bool _busy = false;

  bool get _canApprove => widget.borrowing.status == BorrowingStatus.requested;

  bool get _canReturn => const {
        BorrowingStatus.approved,
        BorrowingStatus.borrowed,
        BorrowingStatus.overdue,
      }.contains(widget.borrowing.status);

  bool get _canEdit => !const {
        BorrowingStatus.returned,
        BorrowingStatus.rejected,
        BorrowingStatus.cancelled,
      }.contains(widget.borrowing.status);

  /// Runs [action] and closes the dialog with a message when it succeeds.
  Future<void> _run(
    Future<String?> Function() action,
    String successMessage,
  ) async {
    setState(() => _busy = true);
    final error = await action();
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      context.showSnackBar(error);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar(successMessage);
  }

  Future<String?> _askText({
    required String title,
    required String label,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 2,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  Future<void> _edit() async {
    final b = widget.borrowing;
    DateTime? expected = b.expectedReturnDate;
    final purposeCtrl = TextEditingController(text: b.purpose ?? '');
    final notesCtrl = TextEditingController(text: b.notes ?? '');

    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          title: const Text('Edit Borrowing'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expected return date'),
                  subtitle: Text(
                    expected == null
                        ? 'Not set'
                        : DateHelper.formatDate(expected),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: expected ?? b.borrowDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setInner(() => expected = picked);
                  },
                ),
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    final purpose = purposeCtrl.text.trim();
    final notes = notesCtrl.text.trim();
    purposeCtrl.dispose();
    notesCtrl.dispose();
    if (save != true || !mounted) return;

    await _run(
      () => ref.read(borrowingNotifierProvider.notifier).update(
            b.id,
            expectedReturnDate: expected,
            purpose: purpose.isEmpty ? null : purpose,
            notes: notes.isEmpty ? null : notes,
          ),
      'Borrowing updated',
    );
  }

  Future<void> _return() async {
    final condition = await _askText(
      title: 'Return item',
      label: 'Condition on return (optional)',
    );
    if (condition == null || !mounted) return;
    await _run(
      () => ref.read(borrowingNotifierProvider.notifier).returnItem(
            widget.borrowing.id,
            condition: condition.isEmpty ? null : condition,
          ),
      'Item returned',
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete borrowing?'),
        content: Text(
          'Delete ${widget.borrowing.borrowNumber}? This cannot be undone.',
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
    if (confirmed != true || !mounted) return;
    await _run(
      () => ref
          .read(borrowingNotifierProvider.notifier)
          .delete(widget.borrowing.id),
      'Borrowing deleted',
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.borrowing;
    return AlertDialog(
      title: Text(b.borrowNumber),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Status', b.status.label),
              _row('Item', b.itemName),
              _row('Borrower', b.borrowerName),
              _row('Quantity', '${b.quantity}'),
              _row('Borrowed', DateHelper.formatDate(b.borrowDate)),
              _row(
                'Expected return',
                DateHelper.formatDate(b.expectedReturnDate),
              ),
              if (b.actualReturnDate != null)
                _row('Returned', DateHelper.formatDate(b.actualReturnDate)),
              if (b.approvedByName != null)
                _row('Approved by', b.approvedByName!),
              if (b.purpose != null && b.purpose!.isNotEmpty)
                _row('Purpose', b.purpose!),
              if (b.conditionOut != null && b.conditionOut!.isNotEmpty)
                _row('Condition out', b.conditionOut!),
              if (b.conditionIn != null && b.conditionIn!.isNotEmpty)
                _row('Condition in', b.conditionIn!),
              if (b.notes != null && b.notes!.isNotEmpty)
                _row('Notes', b.notes!),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : _delete,
          style: TextButton.styleFrom(
            foregroundColor: context.colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
        if (_canEdit)
          TextButton(
            onPressed: _busy ? null : _edit,
            child: const Text('Edit'),
          ),
        if (_canApprove)
          TextButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref
                          .read(borrowingNotifierProvider.notifier)
                          .reject(b.id),
                      'Request rejected',
                    ),
            child: const Text('Reject'),
          ),
        if (_canApprove)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(
                      () => ref
                          .read(borrowingNotifierProvider.notifier)
                          .approve(b.id),
                      'Request approved',
                    ),
            child: const Text('Approve'),
          ),
        if (_canReturn)
          FilledButton(
            onPressed: _busy ? null : _return,
            child: const Text('Return'),
          ),
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
