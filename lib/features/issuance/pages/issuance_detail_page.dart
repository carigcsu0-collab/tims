import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/issuance_model.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/features/issuance/providers/issuance_provider.dart';

/// Read-only detail view for an issuance, with purpose/notes editing.
class IssuanceDetailPage extends ConsumerStatefulWidget {
  const IssuanceDetailPage({super.key, required this.issuance});

  final IssuanceModel issuance;

  @override
  ConsumerState<IssuanceDetailPage> createState() => _IssuanceDetailPageState();
}

class _IssuanceDetailPageState extends ConsumerState<IssuanceDetailPage> {
  late IssuanceModel _issuance = widget.issuance;

  Future<void> _reload() async {
    final result = await ref
        .read(issuanceRepositoryProvider)
        .getById(_issuance.id);
    if (!mounted) return;
    result.fold(
      (failure) => context.showSnackBar(failure.message, isError: true),
      (fresh) => setState(() => _issuance = fresh),
    );
  }

  Future<void> _edit() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _EditIssuanceDialog(
        issuanceId: _issuance.id,
        purpose: _issuance.purpose,
        notes: _issuance.notes,
      ),
    );
    if (saved != true) return;
    await _reload();
    if (!mounted) return;
    ref.read(issuanceNotifierProvider.notifier).refresh();
    context.showSnackBar('Issuance updated');
  }

  String _userName(List<UserModel> users, int id) {
    final match = users.where((u) => u.id == id).firstOrNull;
    return match?.name ?? 'User #$id';
  }

  String _itemName(List<ItemModel> items, int id) {
    final match = items.where((i) => i.id == id).firstOrNull;
    return match?.name ?? 'Item #$id';
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(issuanceRecipientsProvider).value ?? const [];
    final items = ref.watch(issuanceItemOptionsProvider).value ?? const [];
    final iss = _issuance;

    return Scaffold(
      appBar: AppBar(
        title: Text(iss.issuanceNumber),
        actions: [
          IconButton(
            tooltip: 'Edit purpose and notes',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: context.responsivePadding,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Issued to',
                    value: _userName(users, iss.issuedTo),
                  ),
                  _InfoRow(
                    label: 'Issued by',
                    value: _userName(users, iss.issuedBy),
                  ),
                  _InfoRow(
                    label: 'Issue date',
                    value: iss.issueDate.length >= 10
                        ? iss.issueDate.substring(0, 10)
                        : iss.issueDate,
                  ),
                  _InfoRow(label: 'Purpose', value: iss.purpose ?? '-'),
                  _InfoRow(label: 'Notes', value: iss.notes ?? '-'),
                  const SizedBox(height: 24),
                  Text(
                    'Items (${iss.items.length})',
                    style: context.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (iss.items.isEmpty)
                    const Text('No items recorded.')
                  else
                    for (final line in iss.items)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.inventory_2_outlined),
                          ),
                          title: Text(_itemName(items, line.itemId)),
                          subtitle: line.notes != null && line.notes!.isNotEmpty
                              ? Text(line.notes!)
                              : null,
                          trailing: Text(
                            'x${line.quantity}',
                            style: context.textTheme.titleMedium,
                          ),
                        ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: context.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _EditIssuanceDialog extends ConsumerStatefulWidget {
  const _EditIssuanceDialog({
    required this.issuanceId,
    this.purpose,
    this.notes,
  });

  final int issuanceId;
  final String? purpose;
  final String? notes;

  @override
  ConsumerState<_EditIssuanceDialog> createState() =>
      _EditIssuanceDialogState();
}

class _EditIssuanceDialogState extends ConsumerState<_EditIssuanceDialog> {
  late final TextEditingController _purpose = TextEditingController(
    text: widget.purpose ?? '',
  );
  late final TextEditingController _notes = TextEditingController(
    text: widget.notes ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _purpose.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    final error = await ref
        .read(issuanceNotifierProvider.notifier)
        .update(
          widget.issuanceId,
          purpose: _purpose.text.trim().isEmpty ? null : _purpose.text.trim(),
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Issuance'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _purpose,
              decoration: const InputDecoration(labelText: 'Purpose'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
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
