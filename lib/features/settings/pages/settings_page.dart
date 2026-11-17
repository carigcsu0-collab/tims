import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/providers/theme_provider.dart';
import 'package:tims/app/services/providers.dart';
import 'package:tims/app/widgets/csu_logo.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/activity_logs/pages/activity_logs_page.dart';
import 'package:tims/features/profile/pages/profile_page.dart';
import 'package:tims/features/authentication/providers/auth_provider.dart';
import 'package:tims/features/roles/pages/roles_page.dart';
import 'package:tims/features/settings/providers/settings_provider.dart';
import 'package:tims/features/users/pages/users_page.dart';

/// Settings page for app configuration.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsNotifierProvider.notifier).load();
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    ref.read(themeModeProvider.notifier).state = mode;
    final prefsAsync = ref.read(preferencesProvider);
    prefsAsync.whenData((prefs) {
      prefs.setThemeMode(themeModeToString(mode));
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Settings',
                subtitle: 'Configure your application preferences',
                icon: Icons.settings,
              ),
              _buildSection(
                context,
                'Appearance',
                [
                  RadioGroup<ThemeMode>(
                    groupValue: themeMode,
                    onChanged: (v) {
                      if (v != null) _setThemeMode(v);
                    },
                    child: const Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text('Light Mode'),
                          subtitle: Text('Always use light theme'),
                          value: ThemeMode.light,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text('Dark Mode'),
                          subtitle: Text('Always use dark theme'),
                          value: ThemeMode.dark,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text('System Default'),
                          subtitle: Text('Follow system setting'),
                          value: ThemeMode.system,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Notifications',
                [
                  SwitchListTile(
                    title: const Text('Push Notifications'),
                    subtitle: const Text('Receive inventory alerts'),
                    value: _notifications,
                    onChanged: (value) {
                      setState(() => _notifications = value);
                      ref.read(settingsNotifierProvider.notifier).update({
                        'notifications_enabled': value,
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Account',
                [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Profile'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.showSnackBar('Profile - navigate'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showChangePasswordDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outline),
                    title: const Text('User Management'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const UsersPage()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Roles & Permissions'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RolesPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'System',
                [
                  ListTile(
                    leading: const Icon(Icons.history_outlined),
                    title: const Text('Activity Logs'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ActivityLogsPage()),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About this system'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authNotifierProvider.notifier).logout();
                  },
                  icon: Icon(Icons.logout, color: context.colorScheme.error),
                  label: Text(
                    'Logout',
                    style: TextStyle(color: context.colorScheme.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Widget> children,
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
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'CSU TVET Office Inventory Management System',
      applicationVersion: '1.0.0',
      applicationIcon: const CsuLogo(size: 48),
      applicationLegalese: 'Cagayan State University - TVET Office',
    );
  }
}
