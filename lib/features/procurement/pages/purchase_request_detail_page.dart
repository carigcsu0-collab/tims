import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/purchase_request_model.dart';
import 'package:tims/features/procurement/providers/purchase_requests_provider.dart';

/// Shows a purchase request with approve, reject and delete actions.
class PurchaseRequestDetailPage extends ConsumerStatefulWidget {
  const PurchaseRequestDetailPage({super.key, required this.request});

  final PurchaseRequestModel request;

  @override
  ConsumerState<PurchaseRequestDetailPage> createState() =>
      _PurchaseRequestDetailPageState();
}

class _PurchaseRequestDetailPageState
    extends ConsumerState<PurchaseRequestDetailPage> {
  bool _busy = false;

  PurchaseRequestModel get _pr => widget.request;

  bool get _canApprove => _pr.status == PurchaseRequestStatus.pending;

  bool get _canReject =>
      _pr.status == PurchaseRequestStatus.pending ||
      _pr.status == PurchaseRequestStatus.draft;

  bool get _canDelete => _pr.status != PurchaseRequestStatus.converted;

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _approve() async {
    final confirmed = await _confirm(
      title: 'Approve request?',
      message: 'Approve purchase request ${_pr.prNumber}?',
      action: 'Approve',
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => ref.read(purchaseRequestsNotifierProvider.notifier).approve(_pr.id),
      successMessage: 'Purchase request approved',
    );
  }

  Future<void> _reject() async {
    final reason = await _askRejectReason();
    if (reason == null || !mounted) return;
    await _run(
      () => ref
          .read(purchaseRequestsNotifierProvider.notifier)
          .reject(_pr.id, reason),
      successMessage: 'Purchase request rejected',
    );
  }

  Future<String?> _askRejectReason() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _RejectReasonDialog(),
    );
  }

  Future<void> _delete() async {
    final confirmed = await _confirm(
      title: 'Delete request?',
      message: 'Delete "${_pr.prNumber}"? This cannot be undone.',
      action: 'Delete',
    );
    if (!confirmed || !mounted) return;
    await _run(
      () => ref
          .read(purchaseRequestsNotifierProvider.notifier)
          .delete(_pr.id),
      successMessage: 'Purchase request deleted',
    );
  }

  Future<void> _run(
    Future<String?> Function() action, {
    required String successMessage,
  }) async {
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

  @override
  Widget build(BuildContext context) {
    final pr = _pr;
    final hasActions = _canApprove || _canReject;

    return Scaffold(
      appBar: AppBar(
        title: Text(pr.prNumber),
        actions: [
          if (_canDelete)
            IconButton(
              tooltip: 'Delete',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: context.responsivePadding,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pr.prNumber,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusBadge.fromLabel(pr.status.label),
              ],
            ),
            const SizedBox(height: 16),
            _infoRow(context, 'Requested by', pr.requestedByName),
            _infoRow(context, 'Date', DateHelper.formatDate(pr.createdAt)),
            _infoRow(context, 'Department', pr.department ?? '-'),
            _infoRow(context, 'Purpose', pr.purpose ?? '-'),
            if (pr.approvedByName != null)
              _infoRow(context, 'Approved by', pr.approvedByName!),
            if (pr.approvedAt != null)
              _infoRow(
                context,
                'Approved at',
                DateHelper.formatDateTime(pr.approvedAt),
              ),
            if (pr.rejectedReason != null)
              _infoRow(context, 'Rejected reason', pr.rejectedReason!),
            const SizedBox(height: 24),
            Text(
              'Items',
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in pr.items)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.itemName),
                subtitle: Text(
                  '${line.quantity} x ${FormatHelper.currency(line.unitCost)}',
                ),
                trailing: Text(
                  FormatHelper.currency(line.totalCost),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ${FormatHelper.currency(pr.totalAmount)}',
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasActions) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (_canReject)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _reject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colorScheme.error,
                        ),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                      ),
                    ),
                  if (_canReject && _canApprove) const SizedBox(width: 12),
                  if (_canApprove)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _approve,
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Asks for a rejection reason; pops with the trimmed reason.
class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject request?'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Reason *'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: context.colorScheme.error,
          ),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
