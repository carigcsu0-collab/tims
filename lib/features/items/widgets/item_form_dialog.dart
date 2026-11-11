import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/qualification_model.dart';
import 'package:tims/features/items/providers/items_provider.dart';

/// Dialog for creating or editing an inventory item (TVET-aware).
class ItemFormDialog extends ConsumerStatefulWidget {
  const ItemFormDialog({super.key, this.item});

  final ItemModel? item;

  @override
  ConsumerState<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends ConsumerState<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _unit;
  late final TextEditingController _quantity;
  late final TextEditingController _minStock;
  late final TextEditingController _unitCost;
  late final TextEditingController _location;
  late ItemType _type;
  late ItemCondition _condition;
  int? _qualificationId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i?.name);
    _sku = TextEditingController(text: i?.sku);
    _unit = TextEditingController(text: i?.unit ?? 'pcs');
    _quantity = TextEditingController(text: '${i?.quantity ?? 0}');
    _minStock = TextEditingController(text: '${i?.minimumStock ?? 0}');
    _unitCost = TextEditingController(text: '${i?.unitCost ?? 0}');
    _location = TextEditingController(text: i?.location);
    _type = i?.type ?? ItemType.tool;
    _condition = i?.condition ?? ItemCondition.working;
    _qualificationId = i?.qualificationId;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _sku, _unit, _quantity, _minStock, _unitCost, _location,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  String? _nonNegativeInt(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n < 0) ? 'Enter a whole number ≥ 0' : null;
  }

  String? _nonNegativeNum(String? v) {
    final n = double.tryParse(v?.trim() ?? '');
    return (n == null || n < 0) ? 'Enter a number ≥ 0' : null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'sku': _sku.text.trim(),
      'type': _type.name,
      'unit': _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
      'condition': _condition.apiValue,
      'qualification_id': _qualificationId,
      'quantity': int.parse(_quantity.text.trim()),
      'minimum_stock': int.parse(_minStock.text.trim()),
      'unit_cost': double.parse(_unitCost.text.trim()),
      'location': _location.text.trim().isEmpty ? null : _location.text.trim(),
    };

    final error = await ref
        .read(itemsNotifierProvider.notifier)
        .save(data, id: widget.item?.id);

    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final qualifications = ref.watch(qualificationsProvider);
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Item' : 'Add Item'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Item name *'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sku,
                  decoration: const InputDecoration(labelText: 'SKU / Property No. *'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ItemType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Classification *'),
                  items: const [
                    DropdownMenuItem(value: ItemType.tool, child: Text('Tool')),
                    DropdownMenuItem(value: ItemType.equipment, child: Text('Equipment')),
                    DropdownMenuItem(value: ItemType.consumable, child: Text('Consumable')),
                    DropdownMenuItem(value: ItemType.material, child: Text('Material')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  initialValue: _qualificationId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Qualification / Training Program',
                    helperText: qualifications.isLoading ? 'Loading…' : null,
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('None / General'),
                    ),
                    for (final QualificationModel q
                        in qualifications.valueOrNull ?? const [])
                      DropdownMenuItem<int?>(
                        value: q.id,
                        child: Text(q.displayName, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) => setState(() => _qualificationId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ItemCondition>(
                  initialValue: _condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: [
                    for (final c in ItemCondition.values)
                      DropdownMenuItem(value: c, child: Text(c.label)),
                  ],
                  onChanged: (v) => setState(() => _condition = v ?? _condition),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeInt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minStock,
                        decoration: const InputDecoration(
                          labelText: 'Min. restock level',
                        ),
                        keyboardType: TextInputType.number,
                        validator: _nonNegativeInt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _unitCost,
                        decoration: const InputDecoration(labelText: 'Unit cost (₱)'),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: _nonNegativeNum,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(
                    labelText: 'Location (e.g. EIM Workshop)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
