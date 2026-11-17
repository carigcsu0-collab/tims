import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/models/user_model.dart';
import 'package:tims/app/services/providers.dart';

/// Extracts the server's validation message, or a generic fallback.
String _apiErrorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
  }
  return fallback;
}

/// Opens the change-password dialog. Shared with the settings page.
Future<void> showChangePasswordDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
  if (changed == true && context.mounted) {
    context.showSnackBar('Password updated');
  }
}

/// Profile page showing user information and profile editing.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'My Profile',
                subtitle: 'View and update your account information',
                icon: Icons.person,
              ),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: context.colorScheme.primaryContainer,
                      child: Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name.substring(0, 1).toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 36,
                          color: context.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.name ?? 'User',
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (user?.role != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(user!.role!),
                        avatar: const Icon(Icons.shield_outlined, size: 18),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(context, 'Personal Information', [
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Position',
                  value: user?.position ?? 'Not set',
                ),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user?.phone ?? 'Not set',
                ),
                _InfoRow(
                  icon: Icons.business_outlined,
                  label: 'Department',
                  value: user?.department ?? 'Not set',
                ),
                _InfoRow(
                  icon: Icons.school_outlined,
                  label: 'Training Center',
                  value: user?.centerName ?? 'Not set',
                ),
              ]),
              const SizedBox(height: 16),
              _buildInfoCard(context, 'Account Details', [
                _InfoRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Status',
                  value: (user?.isActive ?? true) ? 'Active' : 'Inactive',
                ),
                _InfoRow(
                  icon: Icons.login_outlined,
                  label: 'Last Login',
                  value: DateHelper.formatDateTime(user?.lastLoginAt),
                ),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Member Since',
                  value: DateHelper.formatDate(user?.createdAt),
                ),
              ]),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _editProfile(context),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => showChangePasswordDialog(context),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _EditProfileDialog(),
    );
    if (saved == true && context.mounted) {
      setState(() {});
      context.showSnackBar('Profile updated');
    }
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    List<_InfoRow> rows,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.primary,
            ),
          ),
        ),
        Card(
          child: Column(
            children: rows
                .map((row) => ListTile(
                      leading: Icon(row.icon),
                      title: Text(row.label),
                      subtitle: Text(row.value),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog();

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _positionController;
  late final TextEditingController _departmentController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authServiceProvider).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _positionController = TextEditingController(text: user?.position ?? '');
    _departmentController =
        TextEditingController(text: user?.department ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).put<Map<String, dynamic>>(
        ApiEndpoints.profile,
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'position': _positionController.text.trim(),
          'department': _departmentController.text.trim(),
        },
      );
      ref
          .read(authServiceProvider)
          .updateCurrentUser(UserModel.fromJson(response.data!));
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _apiErrorMessage(e, 'Could not update profile. Try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _positionController,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _departmentController,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ],
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
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).put<Map<String, dynamic>>(
        ApiEndpoints.profileUpdatePassword,
        data: {
          'current_password': _currentController.text,
          'password': _newController.text,
          'password_confirmation': _confirmController.text,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _apiErrorMessage(e, 'Could not change password. Try again.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password (min 8 characters)',
                ),
                validator: (v) =>
                    (v == null || v.length < 8) ? 'Minimum 8 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
                validator: (v) =>
                    v != _newController.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ],
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
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Update'),
        ),
      ],
    );
  }
}
