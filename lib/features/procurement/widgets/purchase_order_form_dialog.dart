import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/features/items/providers/items_provider.dart';
import 'package:tims/features/procurement/providers/purchase_orders_provider.dart';

/// Shows the dialog for creating a purchase order.
Future<void> showPurchaseOrderFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const PurchaseOrderFormDialog(),
  );
}

class _PoLine {
  _PoLine(this.item)
      : quantity = TextEditingController(text: '1'),
        unitCost = TextEditingController(
          text: item.unitCost.toStringAsFixed(2),
        );

  final ItemModel item;
  final TextEditingController quantity;
  final TextEditingController unitCost;

  int get qty => int.tryParse(quantity.text.trim()) ?? 0;
  double get cost => double.tryParse(unitCost.text.trim()) ?? 0;
  double get total => qty * cost;

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
  }
}

class PurchaseOrderFormDialog extends ConsumerStatefulWidget {
  const PurchaseOrderFormDialog({super.key});

  @override
  ConsumerState<PurchaseOrderFormDialog> createState() =>
      _PurchaseOrderFormDialogState();
}

class _PurchaseOrderFormDialogState
    extends ConsumerState<PurchaseOrderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _poNumber;
  final _paymentTerms = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _notes = TextEditingController();
  final List<_PoLine> _lines = [];
  DateTime? _expectedDelivery;
  String? _linesError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _poNumber = TextEditingController(text: _generatePoNumber());
  }

  @override
  void dispose() {
    _poNumber.dispose();
    _paymentTerms.dispose();
    _deliveryAddress.dispose();
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  static String _generatePoNumber() {
    String two(int n) => n.toString().padLeft(2, '0');
    final now = DateTime.now();
    return 'PO-${now.year}${two(now.month)}${two(now.day)}-'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<void> _addItem() async {
    final item = await showDialog<ItemModel>(
      context: context,
      builder: (_) => const _ItemPickerDialog(),
    );
    if (item == null || !mounted) return;
    setState(() {
      _lines.add(_PoLine(item));
      _linesError = null;
    });
  }

  void _removeLine(_PoLine line) {
    setState(() {
      _lines.remove(line);
      line.dispose();
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expectedDelivery ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _expectedDelivery = picked);
  }

  String? _optional(TextEditingController c) {
    final text = c.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (_lines.isEmpty) {
      setState(() => _linesError = 'Add at least one item');
      return;
    }
    if (!valid) return;

    setState(() => _saving = true);
    final error = await ref.read(purchaseOrdersNotifierProvider.notifier).create({
      'po_number': _poNumber.text.trim(),
      'expected_delivery_date':
          _expectedDelivery == null ? null : DateHelper.toIsoDate(_expectedDelivery!),
      'payment_terms': _optional(_paymentTerms),
      'delivery_address': _optional(_deliveryAddress),
      'notes': _optional(_notes),
      'items': [
        for (final line in _lines)
          {
            'item_id': line.item.id,
            'quantity_ordered': line.qty,
            'unit_cost': line.cost,
            'unit': line.item.unit,
          },
      ],
    });
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Purchase order created');
  }

  @override
  Widget build(BuildContext context) {
    final total = _lines.fold<double>(0, (sum, line) => sum + line.total);

    return AlertDialog(
      title: const Text('New Purchase Order'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _poNumber,
                  decoration: const InputDecoration(labelText: 'PO Number *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'PO number is required'
                      : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text(_expectedDelivery == null
                      ? 'Expected delivery date'
                      : 'Expected: ${DateHelper.formatDate(_expectedDelivery)}'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paymentTerms,
                  decoration: const InputDecoration(labelText: 'Payment terms'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deliveryAddress,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Delivery address'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Items *',
                        style: context.textTheme.titleSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
                if (_linesError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _linesError!,
                      style: TextStyle(color: context.colorScheme.error),
                    ),
                  ),
                for (final line in _lines) _buildLine(context, line),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${FormatHelper.currency(total)}',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildLine(BuildContext context, _PoLine line) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${line.item.name} (${line.item.sku})',
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove item',
                  icon: Icon(Icons.delete_outline,
                      color: context.colorScheme.error),
                  onPressed: () => _removeLine(line),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: line.quantity,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty (${line.item.unit})',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      return (n == null || n < 1) ? 'Min 1' : null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: line.unitCost,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(labelText: 'Unit cost'),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      return (n == null || n < 0) ? 'Invalid' : null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text('Line total: ${FormatHelper.currency(line.total)}'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Searches inventory items and returns the one the user picks.
class _ItemPickerDialog extends ConsumerStatefulWidget {
  const _ItemPickerDialog();

  @override
  ConsumerState<_ItemPickerDialog> createState() => _ItemPickerDialogState();
}

class _ItemPickerDialogState extends ConsumerState<_ItemPickerDialog> {
  final _search = TextEditingController();
  List<ItemModel>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final query = _search.text.trim();
    final result = await ref.read(itemsRepositoryProvider).getPaginated(
          perPage: 50,
          search: query.isEmpty ? null : query,
        );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() => _error = failure.message),
      (response) => setState(() {
        _items = response.data;
        _error = null;
      }),
    );
  }

  Widget _body() {
    if (_error != null) return Text(_error!);
    final items = _items;
    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) return const Text('No items found.');
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        return ListTile(
          dense: true,
          title: Text(item.name),
          subtitle: Text('${item.sku} | ${item.unit}'),
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select item'),
      content: SizedBox(
        width: 480,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                labelText: 'Search by name or SKU',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) {
                setState(() => _items = null);
                _load();
              },
            ),
            const SizedBox(height: 8),
            Expanded(child: _body()),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
