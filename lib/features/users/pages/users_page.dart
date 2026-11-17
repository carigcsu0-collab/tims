import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/exceptions/failure.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/paginated_response.dart';
import 'package:tims/features/roles/models/role_models.dart';
import 'package:tims/features/roles/providers/roles_provider.dart';
import 'package:tims/features/users/models/managed_user.dart';
import 'package:tims/features/users/providers/users_provider.dart';
import 'package:tims/features/users/widgets/user_form_dialog.dart';

/// Lists user accounts and lets admins add, edit and delete them.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usersNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _roleLabel(String? role) {
    if (role == null) return 'No role';
    final roles = ref.watch(rolesProvider).value ?? const <RoleModel>[];
    for (final r in roles) {
      if (r.name == role) return r.label;
    }
    return role;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usersNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'User Management',
                subtitle: 'Manage system accounts and their roles',
                icon: Icons.people,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search by name or email...',
                onChanged: (value) =>
                    ref.read(usersNotifierProvider.notifier).setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showUserFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<PaginatedResponse<ManagedUser>> state,
  ) {
    if (state.isLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state.hasError) {
      final error = state.error;
      return ErrorDisplay(
        message: error is Failure ? error.message : '$error',
        onRetry: () => ref.read(usersNotifierProvider.notifier).refresh(),
      );
    }
    final page = state.requireValue;
    if (page.data.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No Users',
        message: 'Add a user account to get started.',
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: page.data.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = page.data[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: context.colorScheme.primaryContainer,
                  child: Text(
                    user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                    style: TextStyle(
                      color: context.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(
                  user.name,
                  style: context.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('${user.email} | ${_roleLabel(user.role)}'),
                trailing: StatusBadge.fromLabel(
                  user.isActive ? 'Active' : 'Inactive',
                ),
                onTap: () => showUserFormDialog(context, user: user),
              );
            },
          ),
        ),
        _PaginationBar(
          page: page.currentPage,
          lastPage: page.lastPage,
          total: page.total,
          onPage: (p) => ref.read(usersNotifierProvider.notifier).goToPage(p),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.lastPage,
    required this.total,
    required this.onPage,
  });

  final int page;
  final int lastPage;
  final int total;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$total total', style: context.textTheme.bodySmall),
          const Spacer(),
          IconButton(
            tooltip: 'Previous page',
            icon: const Icon(Icons.chevron_left),
            onPressed: page > 1 ? () => onPage(page - 1) : null,
          ),
          Text('Page $page of $lastPage'),
          IconButton(
            tooltip: 'Next page',
            icon: const Icon(Icons.chevron_right),
            onPressed: page < lastPage ? () => onPage(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
