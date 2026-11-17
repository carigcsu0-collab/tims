import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/purchase_order_model.dart';
import 'package:tims/core/models/receiving_model.dart';
import 'package:tims/features/receiving/providers/receiving_provider.dart';

/// Read-only detail view of a receiving record with delete support.
class ReceivingDetailPage extends ConsumerWidget {
  const ReceivingDetailPage({super.key, required this.receiving});

  final ReceivingModel receiving;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete receiving record?'),
        content: Text(
          'Delete "${receiving.receivingNumber}"? This cannot be undone. '
          'Stock quantities are not adjusted by this action.',
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
    if (confirmed != true || !context.mounted) return;

    final error = await ref
        .read(receivingNotifierProvider.notifier)
        .delete(receiving.id);
    if (!context.mounted) return;
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Receiving deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(receivingItemOptionsProvider).value ?? const <ItemModel>[];
    final purchaseOrders =
        ref.watch(receivingPurchaseOrderOptionsProvider).value ?? const <PurchaseOrderModel>[];
    final currency = NumberFormat.currency(symbol: '');

    final poMatches =
        purchaseOrders.where((po) => po.id == receiving.purchaseOrderId);
    final poLabel = receiving.purchaseOrderId == null
        ? 'None'
        : poMatches.isEmpty
            ? 'PO #${receiving.purchaseOrderId}'
            : poMatches.first.poNumber;

    final totalValue = receiving.items.fold<double>(
      0,
      (sum, line) => sum + line.quantityReceived * line.unitCost,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(receiving.receivingNumber),
        actions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: context.responsivePadding,
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.event),
                    title: const Text('Received date'),
                    subtitle: Text(receiving.receivedDate),
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Purchase order'),
                    subtitle: Text(poLabel),
                  ),
                  ListTile(
                    leading: const Icon(Icons.notes),
                    title: const Text('Notes'),
                    subtitle: Text(receiving.notes?.isNotEmpty == true
                        ? receiving.notes!
                        : '—'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Total value'),
                    subtitle: Text(currency.format(totalValue).trim()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Items (${receiving.items.length})',
              style: context.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (receiving.items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No items recorded.'),
              ),
            for (final line in receiving.items)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.inventory_2)),
                  title: Text(_itemName(items, line.itemId)),
                  subtitle: Text(
                    'Qty: ${line.quantityReceived} × ${currency.format(line.unitCost).trim()}'
                    '${line.notes != null && line.notes!.isNotEmpty ? '\n${line.notes}' : ''}',
                  ),
                  trailing: Text(
                    currency.format(line.quantityReceived * line.unitCost).trim(),
                  ),
                  isThreeLine: line.notes != null && line.notes!.isNotEmpty,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _itemName(List<ItemModel> items, int itemId) {
    final matches = items.where((i) => i.id == itemId);
    return matches.isEmpty ? 'Item #$itemId' : matches.first.name;
  }
}
