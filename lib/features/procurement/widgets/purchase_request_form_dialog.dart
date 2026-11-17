import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/features/procurement/providers/purchase_requests_provider.dart';

/// Shows the dialog for creating a new purchase request.
Future<void> showPurchaseRequestFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const PurchaseRequestFormDialog(),
  );
}

/// One editable line of a purchase request.
class _LineDraft {
  ItemModel? item;
  final quantity = TextEditingController(text: '1');
  final unitCost = TextEditingController(text: '0');

  int get qty => int.tryParse(quantity.text.trim()) ?? 0;
  double get cost => double.tryParse(unitCost.text.trim()) ?? 0;

  void dispose() {
    quantity.dispose();
    unitCost.dispose();
  }
}

class PurchaseRequestFormDialog extends ConsumerStatefulWidget {
  const PurchaseRequestFormDialog({super.key});

  @override
  ConsumerState<PurchaseRequestFormDialog> createState() =>
      _PurchaseRequestFormDialogState();
}

class _PurchaseRequestFormDialogState
    extends ConsumerState<PurchaseRequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  final _department = TextEditingController();
  final List<_LineDraft> _lines = [_LineDraft()];
  // Removed lines stay alive until dispose, since their fields may still be mounted.
  final List<_LineDraft> _removedLines = [];
  bool _saving = false;

  @override
  void dispose() {
    _purpose.dispose();
    _department.dispose();
    for (final line in [..._lines, ..._removedLines]) {
      line.dispose();
    }
    super.dispose();
  }

  double get _total =>
      _lines.fold(0, (sum, line) => sum + line.qty * line.cost);

  void _removeLine(_LineDraft line) {
    setState(() {
      _lines.remove(line);
      _removedLines.add(line);
    });
  }

  void _selectItem(_LineDraft line, ItemModel item) {
    setState(() {
      line.item = item;
      line.unitCost.text = item.unitCost.toString();
    });
  }

  String? _optional(String text) => text.trim().isEmpty ? null : text.trim();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) {
      context.showSnackBar('You must be signed in to create a request');
      return;
    }
    setState(() => _saving = true);
    final lines = [
      for (final line in _lines)
        {
          'item_id': line.item!.id,
          'quantity': line.qty,
          'unit_cost': line.cost,
          'unit': line.item!.unit,
        },
    ];
    final error = await ref.read(purchaseRequestsNotifierProvider.notifier).save(
          requestedBy: user.id,
          purpose: _optional(_purpose.text),
          department: _optional(_department.text),
          lines: lines,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Purchase request created');
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(purchaseRequestItemOptionsProvider);
    final options = items.valueOrNull ?? const <ItemModel>[];

    return AlertDialog(
      title: const Text('New Purchase Request'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _purpose,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _department,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 16),
                Text('Items *', style: context.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final line in _lines)
                  _buildLine(line, options, items.isLoading),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _lines.add(_LineDraft())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add item'),
                  ),
                ),
                const Divider(),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Total: ${FormatHelper.currency(_total)}',
                    style: context.textTheme.bodyLarge?.copyWith(
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

  Widget _buildLine(
    _LineDraft line,
    List<ItemModel> options,
    bool loadingItems,
  ) {
    return Padding(
      key: ObjectKey(line),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ItemModel>(
                  initialValue: line.item,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Item *',
                    helperText: loadingItems ? 'Loading items...' : null,
                  ),
                  items: [
                    for (final item in options)
                      DropdownMenuItem<ItemModel>(
                        value: item,
                        child: Text(
                          '${item.name} (${item.sku})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  validator: (v) => v == null ? 'Select an item' : null,
                  onChanged: (v) {
                    if (v != null) _selectItem(line, v);
                  },
                ),
              ),
              if (_lines.length > 1)
                IconButton(
                  tooltip: 'Remove item',
                  onPressed: _saving ? null : () => _removeLine(line),
                  icon: Icon(
                    Icons.remove_circle_outline,
                    color: context.colorScheme.error,
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: line.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n < 1) ? 'Min 1' : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: line.unitCost,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Unit cost *'),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return (n == null || n < 0) ? 'Invalid' : null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
