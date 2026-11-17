import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/return_model.dart';
import 'package:tims/features/returns/providers/returns_provider.dart';

/// Shows the create dialog for a return record. Pass [record] to edit its
/// condition and notes.
Future<void> showReturnFormDialog(
  BuildContext context, {
  ReturnModel? record,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => ReturnFormDialog(record: record),
  );
}

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _defaultReturnNumber() {
  final n = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'RET-${n.year}${two(n.month)}${two(n.day)}-${two(n.hour)}${two(n.minute)}${two(n.second)}';
}

class ReturnFormDialog extends ConsumerStatefulWidget {
  const ReturnFormDialog({super.key, this.record});

  final ReturnModel? record;

  @override
  ConsumerState<ReturnFormDialog> createState() => _ReturnFormDialogState();
}

class _ReturnFormDialogState extends ConsumerState<ReturnFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _returnNumber;
  late final TextEditingController _date;
  late final TextEditingController _quantity;
  late final TextEditingController _notes;
  late DateTime _returnDate;
  int? _itemId;
  int? _returnedBy;
  late ReturnCondition _condition;
  bool _saving = false;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _returnDate = DateTime.now();
    _returnNumber = TextEditingController(text: r?.returnNumber ?? _defaultReturnNumber());
    _date = TextEditingController(text: r?.returnDate ?? _formatDate(_returnDate));
    _quantity = TextEditingController(text: '${r?.quantity ?? 1}');
    _notes = TextEditingController(text: r?.notes ?? '');
    _itemId = r?.itemId;
    _returnedBy = r?.returnedBy;
    _condition = r?.condition ?? ReturnCondition.good;
  }

  @override
  void dispose() {
    _returnNumber.dispose();
    _date.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _returnDate = picked;
      _date.text = _formatDate(picked);
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    setState(() => _saving = true);

    final String? error;
    if (_isEdit) {
      final id = widget.record!.id;
      error = await ref.read(returnsNotifierProvider.notifier).update(id, {
        'condition': _condition.name,
        'notes': notes,
      });
      if (error == null) ref.invalidate(returnDetailProvider(id));
    } else {
      final options = ref.read(returnFormOptionsProvider).value;
      final returnedBy = _returnedBy ?? options?.currentUserId;
      if (options == null || _itemId == null || returnedBy == null) {
        setState(() => _saving = false);
        context.showSnackBar('Unable to save: missing item or returned by', isError: true);
        return;
      }
      error = await ref.read(returnsNotifierProvider.notifier).create({
        'return_number': _returnNumber.text.trim(),
        'item_id': _itemId,
        'returned_by': returnedBy,
        'return_date': _formatDate(_returnDate),
        'quantity': int.parse(_quantity.text.trim()),
        'condition': _condition.name,
        'notes': notes,
      });
    }

    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar(_isEdit ? 'Return updated' : 'Return recorded');
  }

  Widget _buildConditionField() {
    return DropdownButtonFormField<ReturnCondition>(
      initialValue: _condition,
      decoration: const InputDecoration(labelText: 'Condition *'),
      items: ReturnCondition.values
          .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _condition = v);
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notes,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Notes'),
    );
  }

  Widget _buildCreateFields(ReturnFormOptions options) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _returnNumber,
          decoration: const InputDecoration(labelText: 'Return number *'),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Return number is required' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _itemId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Item *'),
          items: options.items
              .map((i) => DropdownMenuItem(value: i.id, child: Text(i.name)))
              .toList(),
          onChanged: (v) => setState(() => _itemId = v),
          validator: (v) => v == null ? 'Select an item' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _returnedBy ?? options.currentUserId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Returned by *'),
          items: options.users
              .map((u) => DropdownMenuItem(value: u.id, child: Text(u.name)))
              .toList(),
          onChanged: (v) => setState(() => _returnedBy = v),
          validator: (v) => v == null ? 'Select who returned the item' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _date,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Return date *',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _quantity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity *'),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            return (n == null || n < 1) ? 'Enter a quantity of at least 1' : null;
          },
        ),
        const SizedBox(height: 12),
        _buildConditionField(),
        const SizedBox(height: 12),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildEditFields() {
    final r = widget.record!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Item, date and quantity cannot be changed after recording.',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Return: ${r.returnNumber}'),
        ),
        const SizedBox(height: 12),
        _buildConditionField(),
        const SizedBox(height: 12),
        _buildNotesField(),
      ],
    );
  }

  Widget _buildBody() {
    if (_isEdit) {
      return _buildEditFields();
    }
    final optionsAsync = ref.watch(returnFormOptionsProvider);
    return optionsAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => SizedBox(
        height: 120,
        child: Center(child: Text('Could not load form data: $e')),
      ),
      data: _buildCreateFields,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Edit Return' : 'New Return'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(child: _buildBody()),
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
