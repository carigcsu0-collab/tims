import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/features/receiving/providers/receiving_provider.dart';

/// Shows the dialog for recording a new receiving.
Future<void> showReceivingFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const ReceivingFormDialog(),
  );
}

class ReceivingFormDialog extends ConsumerStatefulWidget {
  const ReceivingFormDialog({super.key});

  @override
  ConsumerState<ReceivingFormDialog> createState() =>
      _ReceivingFormDialogState();
}

class _ReceivingLine {
  _ReceivingLine()
      : quantity = TextEditingController(text: '1'),
        unitCost = TextEditingController();

  int? itemId;
  final TextEditingController quantity;
  final TextEditingController unitCost;

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
  }
}

class _ReceivingFormDialogState extends ConsumerState<ReceivingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('yyyy-MM-dd');
  late final TextEditingController _number;
  late final TextEditingController _date;
  final _notes = TextEditingController();
  final List<_ReceivingLine> _lines = [_ReceivingLine()];
  int? _purchaseOrderId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _number = TextEditingController(
      text: 'RCV-${DateFormat('yyyyMMdd-HHmmss').format(now)}',
    );
    _date = TextEditingController(text: _dateFormat.format(now));
  }

  @override
  void dispose() {
    _number.dispose();
    _date.dispose();
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_date.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _date.text = _dateFormat.format(picked);
    }
  }

  void _removeLine(_ReceivingLine line) {
    setState(() {
      _lines.remove(line);
      line.dispose();
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final items = _lines
        .map((line) => <String, dynamic>{
              'item_id': line.itemId,
              'quantity_received': int.parse(line.quantity.text.trim()),
              'unit_cost': double.tryParse(line.unitCost.text.trim()) ?? 0,
            })
        .toList();

    final notes = _notes.text.trim();
    final error = await ref.read(receivingNotifierProvider.notifier).save(
          receivingNumber: _number.text.trim(),
          purchaseOrderId: _purchaseOrderId,
          receivedDate: _date.text,
          notes: notes.isEmpty ? null : notes,
          items: items,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Receiving recorded');
  }

  @override
  Widget build(BuildContext context) {
    final itemOptions = ref.watch(receivingItemOptionsProvider);
    final poOptions = ref.watch(receivingPurchaseOrderOptionsProvider);
    final items = itemOptions.value ?? const <ItemModel>[];
    final purchaseOrders = poOptions.value ?? const [];

    return AlertDialog(
      title: const Text('New Receiving Record'),
      content: SizedBox(
        width: context.screenWidth < 600 ? double.maxFinite : 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _number,
                  decoration:
                      const InputDecoration(labelText: 'Receiving number *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Receiving number is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _date,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Received date *',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _pickDate,
                    ),
                  ),
                  onTap: _pickDate,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Date is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _purchaseOrderId,
                  decoration: const InputDecoration(
                    labelText: 'Purchase order (optional)',
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ...purchaseOrders.map(
                      (po) => DropdownMenuItem<int?>(
                        value: po.id,
                        child: Text(po.poNumber),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _purchaseOrderId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Items *', style: context.textTheme.titleSmall),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _lines.add(_ReceivingLine())),
                      icon: const Icon(Icons.add),
                      label: const Text('Add item'),
                    ),
                  ],
                ),
                if (itemOptions.hasError)
                  Text(
                    'Could not load items',
                    style: TextStyle(color: context.colorScheme.error),
                  ),
                for (final line in _lines) _buildLine(line, items),
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
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  Widget _buildLine(_ReceivingLine line, List<ItemModel> items) {
    return Padding(
      key: ObjectKey(line),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<int>(
            initialValue: line.itemId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Item *'),
            items: items
                .map((item) => DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(
                        '${item.name} (${item.sku})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            validator: (v) => v == null ? 'Select an item' : null,
            onChanged: (v) {
              setState(() => line.itemId = v);
              final matches = items.where((i) => i.id == v);
              if (matches.isNotEmpty && line.unitCost.text.trim().isEmpty) {
                line.unitCost.text = matches.first.unitCost.toString();
              }
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n < 1)
                        ? 'Enter a whole number ≥ 1'
                        : null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: line.unitCost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Unit cost'),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return null;
                    final n = double.tryParse(t);
                    return (n == null || n < 0) ? 'Invalid cost' : null;
                  },
                ),
              ),
              IconButton(
                tooltip: 'Remove item',
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _lines.length > 1 ? () => _removeLine(line) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
