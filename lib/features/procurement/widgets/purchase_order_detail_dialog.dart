import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/purchase_order_model.dart';
import 'package:tims/features/procurement/providers/purchase_orders_provider.dart';

/// Shows the detail dialog for a purchase order.
Future<void> showPurchaseOrderDetailDialog(
  BuildContext context,
  PurchaseOrderModel po,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => PurchaseOrderDetailDialog(po: po),
  );
}

class PurchaseOrderDetailDialog extends ConsumerStatefulWidget {
  const PurchaseOrderDetailDialog({super.key, required this.po});

  final PurchaseOrderModel po;

  @override
  ConsumerState<PurchaseOrderDetailDialog> createState() =>
      _PurchaseOrderDetailDialogState();
}

class _PurchaseOrderDetailDialogState
    extends ConsumerState<PurchaseOrderDetailDialog> {
  late PurchaseOrderModel _po;
  late PurchaseOrderStatus _newStatus;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _po = widget.po;
    _newStatus = _po.status;
    _refresh();
  }

  /// Replaces the list-sourced copy with the latest copy from the API.
  Future<void> _refresh() async {
    final fresh = await ref
        .read(purchaseOrdersNotifierProvider.notifier)
        .fetchById(_po.id);
    if (!mounted || fresh == null) return;
    setState(() {
      _po = fresh;
      _newStatus = fresh.status;
    });
  }

  Future<void> _updateStatus() async {
    setState(() => _busy = true);
    final error = await ref
        .read(purchaseOrdersNotifierProvider.notifier)
        .updateStatus(_po.id, _newStatus);
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Status updated to ${_newStatus.label}');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete purchase order?'),
        content: Text('Delete "${_po.poNumber}"? This cannot be undone.'),
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
    setState(() => _busy = true);
    final error = await ref
        .read(purchaseOrdersNotifierProvider.notifier)
        .delete(_po.id);
    if (!mounted) return;
    if (error != null) {
      setState(() => _busy = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Purchase order deleted');
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
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
    final po = _po;
    final statusChanged = _newStatus != po.status;

    return AlertDialog(
      title: Text(po.poNumber),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusBadge.fromLabel(po.status.label),
                  const Spacer(),
                  Text(
                    FormatHelper.currency(po.totalAmount),
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(context, 'Expected delivery',
                  DateHelper.formatDate(po.expectedDeliveryDate)),
              _infoRow(context, 'Actual delivery',
                  DateHelper.formatDate(po.actualDeliveryDate)),
              _infoRow(context, 'Payment terms', po.paymentTerms ?? '-'),
              _infoRow(context, 'Delivery address', po.deliveryAddress ?? '-'),
              _infoRow(context, 'Notes', po.notes ?? '-'),
              _infoRow(context, 'Created by', po.createdByName ?? '-'),
              _infoRow(context, 'Created', DateHelper.formatDateTime(po.createdAt)),
              const Divider(height: 24),
              Text('Items (${po.items.length})',
                  style: context.textTheme.titleSmall),
              const SizedBox(height: 4),
              for (final line in po.items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.itemName),
                  subtitle: Text(
                    '${line.quantityOrdered} ${line.unit} x '
                    '${FormatHelper.currency(line.unitCost)}'
                    '${line.quantityReceived > 0 ? ' | received ${line.quantityReceived}' : ''}',
                  ),
                  trailing: Text(FormatHelper.currency(line.totalCost)),
                ),
              const Divider(height: 24),
              DropdownButtonFormField<PurchaseOrderStatus>(
                initialValue: _newStatus,
                items: [
                  for (final s in PurchaseOrderStatus.values)
                    DropdownMenuItem(value: s, child: Text(s.label)),
                ],
                onChanged: _busy
                    ? null
                    : (value) {
                        if (value != null) setState(() => _newStatus = value);
                      },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: (_busy || !statusChanged) ? null : _updateStatus,
                  child: const Text('Update status'),
                ),
              ),
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
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
