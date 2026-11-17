import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/models/maintenance_model.dart';
import 'package:tims/features/maintenance/providers/maintenance_provider.dart';

/// Shows the dialog for marking a maintenance record as completed.
Future<void> showCompleteMaintenanceDialog(
  BuildContext context,
  MaintenanceModel maintenance,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => CompleteMaintenanceDialog(maintenance: maintenance),
  );
}

class CompleteMaintenanceDialog extends ConsumerStatefulWidget {
  const CompleteMaintenanceDialog({super.key, required this.maintenance});

  final MaintenanceModel maintenance;

  @override
  ConsumerState<CompleteMaintenanceDialog> createState() =>
      _CompleteMaintenanceDialogState();
}

class _CompleteMaintenanceDialogState
    extends ConsumerState<CompleteMaintenanceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _findings;
  late final TextEditingController _recommendations;
  late final TextEditingController _cost;
  DateTime? _nextDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _findings = TextEditingController(text: m.findings);
    _recommendations = TextEditingController(text: m.recommendations);
    _cost = TextEditingController(text: m.cost.toString());
    _nextDate = m.nextMaintenanceDate;
  }

  @override
  void dispose() {
    _findings.dispose();
    _recommendations.dispose();
    _cost.dispose();
    super.dispose();
  }

  String? _optional(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _nextDate = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final error = await ref.read(maintenanceNotifierProvider.notifier).complete(
          widget.maintenance.id,
          findings: _optional(_findings.text),
          recommendations: _optional(_recommendations.text),
          cost: double.parse(_cost.text.trim()),
          nextMaintenanceDate: _nextDate,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('Maintenance marked as completed');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mark Maintenance Complete'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _findings,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Findings'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recommendations,
                  maxLines: 3,
                  decoration:
                      const InputDecoration(labelText: 'Recommendations'),
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
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Next maintenance date',
                    suffixIcon: _nextDate == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _nextDate = null),
                          ),
                  ),
                  child: InkWell(
                    onTap: _pickNextDate,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _nextDate == null
                                ? 'Not set'
                                : DateHelper.formatDate(_nextDate),
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
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
          child: Text(_saving ? 'Saving...' : 'Mark complete'),
        ),
      ],
    );
  }
}
