import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/features/borrowing/providers/borrowing_provider.dart';

/// Shows the dialog for creating a new borrowing request.
Future<void> showBorrowingFormDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const BorrowingFormDialog(),
  );
}

class BorrowingFormDialog extends ConsumerStatefulWidget {
  const BorrowingFormDialog({super.key});

  @override
  ConsumerState<BorrowingFormDialog> createState() =>
      _BorrowingFormDialogState();
}

class _BorrowingFormDialogState extends ConsumerState<BorrowingFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController(text: '1');
  final _purpose = TextEditingController();
  final _conditionOut = TextEditingController();
  final _notes = TextEditingController();
  int? _itemId;
  int? _borrowerId;
  DateTime _borrowDate = DateTime.now();
  DateTime? _expectedReturnDate;
  bool _saving = false;

  @override
  void dispose() {
    _quantity.dispose();
    _purpose.dispose();
    _conditionOut.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _optional(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final error =
        await ref.read(borrowingNotifierProvider.notifier).save(
              itemId: _itemId!,
              borrowerId: _borrowerId!,
              borrowDate: _borrowDate,
              expectedReturnDate: _expectedReturnDate,
              quantity: int.parse(_quantity.text.trim()),
              purpose: _optional(_purpose.text),
              conditionOut: _optional(_conditionOut.text),
              notes: _optional(_notes.text),
            );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Borrowing request created');
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(borrowableItemsProvider);
    final borrowers = ref.watch(borrowerOptionsProvider);

    return AlertDialog(
      title: const Text('New Borrowing'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                items.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load items: $e'),
                  data: (list) => DropdownButtonFormField<int>(
                    initialValue: _itemId,
                    decoration: const InputDecoration(labelText: 'Item *'),
                    isExpanded: true,
                    items: [
                      for (final i in list)
                        DropdownMenuItem(value: i.id, child: Text(i.name)),
                    ],
                    onChanged: (v) => setState(() => _itemId = v),
                    validator: (v) => v == null ? 'Select an item' : null,
                  ),
                ),
                const SizedBox(height: 12),
                borrowers.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load borrowers: $e'),
                  data: (list) => DropdownButtonFormField<int>(
                    initialValue: _borrowerId,
                    decoration: const InputDecoration(labelText: 'Borrower *'),
                    isExpanded: true,
                    items: [
                      for (final u in list)
                        DropdownMenuItem(value: u.id, child: Text(u.name)),
                    ],
                    onChanged: (v) => setState(() => _borrowerId = v),
                    validator: (v) => v == null ? 'Select a borrower' : null,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity *'),
                  validator: (v) {
                    final n = int.tryParse(v?.trim() ?? '');
                    return (n == null || n < 1)
                        ? 'Enter a quantity of at least 1'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Borrow date'),
                  subtitle: Text(DateHelper.formatDate(_borrowDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(
                    initial: _borrowDate,
                    onPicked: (d) => _borrowDate = d,
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expected return date'),
                  subtitle: Text(
                    _expectedReturnDate == null
                        ? 'Not set'
                        : DateHelper.formatDate(_expectedReturnDate),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _pickDate(
                    initial: _expectedReturnDate ?? _borrowDate,
                    onPicked: (d) => _expectedReturnDate = d,
                  ),
                ),
                TextFormField(
                  controller: _purpose,
                  decoration: const InputDecoration(labelText: 'Purpose'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _conditionOut,
                  decoration:
                      const InputDecoration(labelText: 'Condition when issued'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
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
