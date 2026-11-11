import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/app/services/providers.dart';

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
                  onPressed: () =>
                      context.showSnackBar('Edit profile - coming soon'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
