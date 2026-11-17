import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/roles/models/role_models.dart';
import 'package:tims/features/roles/providers/roles_provider.dart';
import 'package:tims/features/users/models/managed_user.dart';
import 'package:tims/features/users/providers/users_provider.dart';

/// Shows the create/edit dialog for a user. Pass [user] to edit.
Future<void> showUserFormDialog(
  BuildContext context, {
  ManagedUser? user,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => UserFormDialog(user: user),
  );
}

class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key, this.user});

  final ManagedUser? user;

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _phone;
  late final TextEditingController _position;
  late final TextEditingController _department;
  late final TextEditingController _centerName;
  late String? _role;
  late bool _isActive;
  bool _saving = false;

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name = TextEditingController(text: u?.name ?? '');
    _email = TextEditingController(text: u?.email ?? '');
    _password = TextEditingController();
    _phone = TextEditingController(text: u?.phone ?? '');
    _position = TextEditingController(text: u?.position ?? '');
    _department = TextEditingController(text: u?.department ?? '');
    _centerName = TextEditingController(text: u?.centerName ?? '');
    _role = u?.role;
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _position.dispose();
    _department.dispose();
    _centerName.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final data = <String, dynamic>{
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'role': _role,
      'phone': _nullIfEmpty(_phone),
      'position': _nullIfEmpty(_position),
      'department': _nullIfEmpty(_department),
      'center_name': _nullIfEmpty(_centerName),
      'is_active': _isActive,
    };
    // On edit, an empty password means "keep the current password".
    if (_password.text.isNotEmpty) {
      data['password'] = _password.text;
    }

    final error = await ref
        .read(usersNotifierProvider.notifier)
        .save(id: widget.user?.id, data: data);
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar(_isEdit ? 'User updated' : 'User created');
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text('Delete "${widget.user!.name}"? This cannot be undone.'),
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
    if (confirmed != true) return;
    final error = await ref
        .read(usersNotifierProvider.notifier)
        .delete(widget.user!.id);
    if (!mounted) return;
    if (error != null) {
      context.showSnackBar(error, isError: true);
      return;
    }
    Navigator.of(context).pop();
    context.showSnackBar('User deleted');
  }

  @override
  Widget build(BuildContext context) {
    final roles = ref.watch(rolesProvider);
    final roleItems = roles.value ?? const <RoleModel>[];

    return AlertDialog(
      title: Text(_isEdit ? 'Edit User' : 'New User'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Full name *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email *'),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Email is required';
                    if (!text.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _isEdit ? 'New password' : 'Password *',
                    helperText: _isEdit
                        ? 'Leave blank to keep the current password'
                        : null,
                  ),
                  validator: (v) {
                    final text = v ?? '';
                    if (!_isEdit && text.isEmpty) {
                      return 'Password is required';
                    }
                    if (text.isNotEmpty && text.length < 8) {
                      return 'Use at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    helperText: roles.isLoading ? 'Loading roles...' : null,
                  ),
                  items: [
                    for (final role in roleItems)
                      DropdownMenuItem(value: role.name, child: Text(role.label)),
                  ],
                  onChanged: (v) => setState(() => _role = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _position,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _department,
                  decoration: const InputDecoration(labelText: 'Department'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _centerName,
                  decoration: const InputDecoration(labelText: 'Center name'),
                ),
                const SizedBox(height: 8),
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
      ),
      actions: [
        if (_isEdit)
          TextButton(
            onPressed: _saving ? null : _delete,
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
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
