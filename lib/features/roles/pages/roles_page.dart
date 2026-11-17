import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/roles/models/role_models.dart';
import 'package:tims/features/roles/providers/roles_provider.dart';

/// Read-only view of each role and the permissions it grants.
class RolesPage extends ConsumerWidget {
  const RolesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles & Permissions')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Roles & Permissions',
                subtitle: 'What each role is allowed to do',
                icon: Icons.security,
              ),
              Expanded(child: _buildBody(context, ref)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(rolesProvider);

    if (roles.isLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (roles.hasError) {
      final error = roles.error;
      return ErrorDisplay(
        message: error is Failure ? error.message : '$error',
        onRetry: () => ref.invalidate(rolesProvider),
      );
    }
    final list = roles.requireValue;
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final role = list[index];
        return ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: context.colorScheme.primaryContainer,
            child: Icon(
              Icons.admin_panel_settings_outlined,
              color: context.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            role.label,
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: role.description != null ? Text(role.description!) : null,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          children: [_RolePermissions(roleName: role.name)],
        );
      },
    );
  }
}

class _RolePermissions extends ConsumerWidget {
  const _RolePermissions({required this.roleName});

  final String roleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final granted = ref.watch(rolePermissionsProvider(roleName));
    final permissions = ref.watch(permissionsProvider);

    if (granted.isLoading || permissions.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (granted.hasError || permissions.hasError) {
      final error = granted.error ?? permissions.error;
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error is Failure ? error.message : '$error'),
      );
    }

    final grantedNames = granted.requireValue;
    final allAccess = grantedNames.contains('*');

    final byModule = <String, List<PermissionModel>>{};
    for (final p in permissions.requireValue) {
      byModule.putIfAbsent(p.module, () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in byModule.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _titleCase(entry.key),
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.primary,
              ),
            ),
          ),
          for (final permission in entry.value)
            ListTile(
              dense: true,
              leading: Icon(
                (allAccess || grantedNames.contains(permission.name))
                    ? Icons.check_circle
                    : Icons.cancel_outlined,
                color: (allAccess || grantedNames.contains(permission.name))
                    ? Colors.green
                    : context.colorScheme.outline,
              ),
              title: Text(permission.label),
            ),
        ],
      ],
    );
  }

  String _titleCase(String value) => value
      .split(RegExp(r'[-\s]'))
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
