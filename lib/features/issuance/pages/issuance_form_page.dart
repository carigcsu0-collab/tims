import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/features/issuance/providers/issuance_provider.dart';
import 'package:tims/features/issuance/widgets/issuance_line_row.dart';

/// Form for recording a new issuance. Pops with `true` when saved.
class IssuanceFormPage extends ConsumerStatefulWidget {
  const IssuanceFormPage({super.key});

  @override
  ConsumerState<IssuanceFormPage> createState() => _IssuanceFormPageState();
}

class _IssuanceFormPageState extends ConsumerState<IssuanceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _number;
  final _purpose = TextEditingController();
  final _notes = TextEditingController();
  final _lines = <IssuanceLine>[IssuanceLine()];
  DateTime _issueDate = DateTime.now();
  int? _issuedTo;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _number = TextEditingController(text: _generateNumber(DateTime.now()));
  }

  @override
  void dispose() {
    _number.dispose();
    _purpose.dispose();
    _notes.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  static String _generateNumber(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${t.year}${two(t.month)}${two(t.day)}';
    final time = '${two(t.hour)}${two(t.minute)}${two(t.second)}';
    return 'ISS-$date-$time';
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _issueDate = picked);
  }

  void _addLine() => setState(() => _lines.add(IssuanceLine()));

  void _removeLine(int index) {
    setState(() {
      _lines.removeAt(index).dispose();
    });
  }

  Future<void> _submit(List<ItemModel> itemOptions) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final items = [
      for (final line in _lines)
        {
          'item_id': line.itemId,
          'quantity': int.parse(line.quantity.text.trim()),
          if (line.notes.text.trim().isNotEmpty)
            'notes': line.notes.text.trim(),
        },
    ];

    final error = await ref
        .read(issuanceNotifierProvider.notifier)
        .save(
          issuanceNumber: _number.text.trim(),
          issuedTo: _issuedTo!,
          issueDate: _formatDate(_issueDate),
          purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
          items: items,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop(true);
    context.showSnackBar('Issuance recorded');
  }

  @override
  Widget build(BuildContext context) {
    final recipients = ref.watch(issuanceRecipientsProvider);
    final itemOptions = ref.watch(issuanceItemOptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Issuance')),
      body: SafeArea(
        child: recipients.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorDisplay(
            message: e.toString(),
            onRetry: () => ref.invalidate(issuanceRecipientsProvider),
          ),
          data: (users) => itemOptions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ErrorDisplay(
              message: e.toString(),
              onRetry: () => ref.invalidate(issuanceItemOptionsProvider),
            ),
            data: (items) => _buildForm(users, items),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(List<UserModel> users, List<ItemModel> items) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: context.responsivePadding,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _number,
                    decoration: const InputDecoration(
                      labelText: 'Issuance number *',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Issuance number is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _issuedTo,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Issued to *'),
                    items: [
                      for (final user in users)
                        DropdownMenuItem(
                          value: user.id,
                          child: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _issuedTo = v),
                    validator: (v) => v == null ? 'Select a recipient' : null,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Issue date *',
                    ),
                    child: InkWell(
                      onTap: _pickDate,
                      child: Row(
                        children: [
                          Expanded(child: Text(_formatDate(_issueDate))),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _purpose,
                    decoration: const InputDecoration(labelText: 'Purpose'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Items', style: context.textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addLine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add item'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _lines.length; i++)
                    IssuanceLineRow(
                      key: ObjectKey(_lines[i]),
                      line: _lines[i],
                      items: items,
                      onItemChanged: (v) =>
                          setState(() => _lines[i].itemId = v),
                      onRemove: () => _removeLine(i),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : () => _submit(items),
                    child: Text(_saving ? 'Saving...' : 'Record issuance'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
