import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/models/maintenance_model.dart';
import 'package:tims/features/maintenance/providers/maintenance_provider.dart';

/// Shows the dialog for scheduling a new maintenance record.
Future<void> showMaintenanceFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const MaintenanceFormDialog(),
  );
}

class MaintenanceFormDialog extends ConsumerStatefulWidget {
  const MaintenanceFormDialog({super.key});

  @override
  ConsumerState<MaintenanceFormDialog> createState() =>
      _MaintenanceFormDialogState();
}

class _MaintenanceFormDialogState extends ConsumerState<MaintenanceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  final _technician = TextEditingController();
  final _cost = TextEditingController(text: '0');
  final _description = TextEditingController();
  int? _itemId;
  MaintenanceType _type = MaintenanceType.preventive;
  DateTime _scheduledDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(
      text: 'MNT-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}',
    );
  }

  @override
  void dispose() {
    _number.dispose();
    _technician.dispose();
    _cost.dispose();
    _description.dispose();
    super.dispose();
  }

  String? _optional(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final error = await ref.read(maintenanceNotifierProvider.notifier).save({
      'maintenance_number': _number.text.trim(),
      'item_id': _itemId,
      'type': _type.name,
      'scheduled_date': DateHelper.toIsoDate(_scheduledDate),
      'technician': _optional(_technician.text),
      'cost': double.parse(_cost.text.trim()),
      'description': _optional(_description.text),
    });
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Maintenance record created');
  }

  @override
  Widget build(BuildContext context) {
    final itemOptions = ref.watch(maintenanceItemOptionsProvider);

    return AlertDialog(
      title: const Text('New Maintenance Record'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                itemOptions.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (error, _) => Text(
                    'Could not load items: $error',
                    style: TextStyle(color: context.colorScheme.error),
                  ),
                  data: (items) => DropdownButtonFormField<int>(
                    initialValue: _itemId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Item *'),
                    items: [
                      for (final item in items)
                        DropdownMenuItem<int>(
                          value: item.id,
                          child: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (v) => v == null ? 'Select an item' : null,
                    onChanged: (v) => setState(() => _itemId = v),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _number,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance number *',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Maintenance number is required'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MaintenanceType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Type *'),
                  items: [
                    for (final t in MaintenanceType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Scheduled date *',
                  ),
                  child: InkWell(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(DateHelper.formatDate(_scheduledDate)),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _technician,
                  decoration: const InputDecoration(labelText: 'Technician'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cost,
                  decoration: const InputDecoration(labelText: 'Cost'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.trim() ?? '');
                    return (n == null || n < 0)
                        ? 'Enter a number ≥ 0'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
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
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
