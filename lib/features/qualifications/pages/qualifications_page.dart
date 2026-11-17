import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/qualification_model.dart';
import 'package:tims/features/qualifications/providers/qualifications_provider.dart';

const _ncLevels = ['NC I', 'NC II', 'NC III', 'NC IV'];

/// Lists TVET qualifications and lets the user add, edit and delete them.
class QualificationsPage extends ConsumerStatefulWidget {
  const QualificationsPage({super.key});

  @override
  ConsumerState<QualificationsPage> createState() => _QualificationsPageState();
}

class _QualificationsPageState extends ConsumerState<QualificationsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qualificationsNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm([QualificationModel? existing]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _QualificationFormDialog(existing: existing),
    );
    if (saved == true && mounted) {
      context.showSnackBar(
        existing == null ? 'Qualification added' : 'Qualification updated',
      );
    }
  }

  Future<void> _confirmDelete(QualificationModel q) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete qualification?'),
        content: Text('"${q.displayName}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error =
        await ref.read(qualificationsNotifierProvider.notifier).delete(q.id);
    if (!mounted) return;
    context.showSnackBar(error ?? 'Qualification deleted');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qualificationsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Qualifications')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Qualifications',
                subtitle: 'TVET training programs used to tag inventory items',
                icon: Icons.verified,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search qualifications...',
                onChanged: (value) => ref
                    .read(qualificationsNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, QualificationsState state) {
    if (state is QualificationsLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is QualificationsError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(qualificationsNotifierProvider.notifier).refresh(),
      );
    }
    if (state is QualificationsLoaded) {
      if (state.qualifications.isEmpty) {
        return const EmptyState(
          icon: Icons.verified_outlined,
          title: 'No Qualifications',
          message: 'Add a TVET qualification to get started.',
        );
      }
      return ListView.separated(
        itemCount: state.qualifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final q = state.qualifications[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.verified,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              q.displayName,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text('Code: ${q.code} | ${q.itemsCount} items'),
            onTap: () => _openForm(q),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge.fromLabel(q.isActive ? 'Active' : 'Inactive'),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(q),
                ),
              ],
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}

class _QualificationFormDialog extends ConsumerStatefulWidget {
  const _QualificationFormDialog({this.existing});

  final QualificationModel? existing;

  @override
  ConsumerState<_QualificationFormDialog> createState() =>
      _QualificationFormDialogState();
}

class _QualificationFormDialogState
    extends ConsumerState<_QualificationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late String? _ncLevel;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _codeController = TextEditingController(text: e?.code ?? '');
    _ncLevel = e?.ncLevel;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final error = await ref.read(qualificationsNotifierProvider.notifier).save(
          id: widget.existing?.id,
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          ncLevel: _ncLevel,
          isActive: _isActive,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Qualification' : 'Add Qualification'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Electrical Installation and Maintenance',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'EIM-NCII',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Code is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _ncLevel,
                decoration: const InputDecoration(labelText: 'NC Level'),
                items: [
                  for (final level in _ncLevels)
                    DropdownMenuItem(value: level, child: Text(level)),
                ],
                onChanged: (v) => setState(() => _ncLevel = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ],
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
