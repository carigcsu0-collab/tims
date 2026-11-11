import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tims/app/config/app_config.dart';
import 'package:tims/app/routes/route_paths.dart';
import 'package:tims/app/services/providers.dart';
import 'package:tims/app/widgets/csu_logo.dart';
import 'package:tims/core/extensions/context_extensions.dart';

/// Navigation destinations for the main app shell.
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

const _navItems = <_NavItem>[
  _NavItem(icon: Icons.dashboard_outlined, label: 'Dashboard', path: RoutePaths.dashboard),
  _NavItem(icon: Icons.inventory_2_outlined, label: 'Inventory', path: RoutePaths.inventory),
  _NavItem(icon: Icons.category_outlined, label: 'Categories', path: RoutePaths.categories),
  _NavItem(icon: Icons.widgets_outlined, label: 'Items', path: RoutePaths.items),
  _NavItem(icon: Icons.local_shipping_outlined, label: 'Suppliers', path: RoutePaths.suppliers),
  _NavItem(icon: Icons.request_quote_outlined, label: 'Purchase Requests', path: RoutePaths.purchaseRequests),
  _NavItem(icon: Icons.receipt_long_outlined, label: 'Purchase Orders', path: RoutePaths.purchaseOrders),
  _NavItem(icon: Icons.inbox_outlined, label: 'Receiving', path: RoutePaths.receiving),
  _NavItem(icon: Icons.outbox_outlined, label: 'Issuance', path: RoutePaths.issuance),
  _NavItem(icon: Icons.swap_horiz_outlined, label: 'Borrowing', path: RoutePaths.borrowing),
  _NavItem(icon: Icons.undo_outlined, label: 'Returns', path: RoutePaths.returns),
  _NavItem(icon: Icons.build_outlined, label: 'Maintenance', path: RoutePaths.maintenance),
  _NavItem(icon: Icons.assessment_outlined, label: 'Reports', path: RoutePaths.reports),
  _NavItem(icon: Icons.notifications_outlined, label: 'Notifications', path: RoutePaths.notifications),
  _NavItem(icon: Icons.settings_outlined, label: 'Settings', path: RoutePaths.settings),
];

/// Responsive main shell with adaptive navigation (NavigationRail on desktop,
/// NavigationBar on mobile, Drawer on tablet).
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelectedIndex();
  }

  void _syncSelectedIndex() {
    final location = GoRouterState.of(context).matchedLocation;
    final index = _navItems.indexWhere((item) => location.startsWith(item.path));
    if (index != -1 && index != _selectedIndex) {
      setState(() => _selectedIndex = index);
    }
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final isTablet = context.isTablet;

    if (isDesktop) {
      return _buildDesktopShell();
    } else if (isTablet) {
      return _buildTabletShell();
    } else {
      return _buildMobileShell();
    }
  }

  Widget _buildDesktopShell() {
    final user = ref.watch(authServiceProvider).currentUser;
    return Scaffold(
      body: Row(
        children: [
          SingleChildScrollView(
            child: IntrinsicHeight(
              child: NavigationRail(
                extended: true,
                selectedIndex: _selectedIndex,
                onDestinationSelected: _onDestinationSelected,
                leading: _buildLogoHeader(),
                trailing: _buildUserTile(user),
                destinations: _navItems
                    .map((item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.icon),
                          label: Text(item.label),
                        ))
                    .toList(),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildTabletShell() {
    return Scaffold(
      appBar: _buildBrandAppBar(),
      drawer: _buildDrawer(),
      body: widget.child,
    );
  }

  Widget _buildMobileShell() {
    final visibleItems = _navItems.take(5).toList();
    return Scaffold(
      appBar: _buildBrandAppBar(),
      drawer: _buildDrawer(),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 5 ? _selectedIndex : 0,
        onDestinationSelected: _onDestinationSelected,
        destinations: visibleItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  PreferredSizeWidget _buildBrandAppBar() {
    return AppBar(
      toolbarHeight: 56,
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      title: const CsuBrandHeader(logoSize: 36, onDark: true),
    );
  }

  Widget _buildDrawer() {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        _onDestinationSelected(index);
        Navigator.pop(context);
      },
      children: [
        _buildLogoHeader(),
        ..._navItems.map((item) => NavigationDrawerDestination(
              icon: Icon(item.icon),
              label: Text(item.label),
            )),
      ],
    );
  }

  Widget _buildLogoHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CsuBrandHeader(logoSize: 44),
          const SizedBox(height: 8),
          Text(
            'Inventory Management System',
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(dynamic user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: context.colorScheme.primaryContainer,
            child: Text(
              (user?.name.isNotEmpty ?? false)
                  ? user!.name.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(color: context.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.name ?? 'User',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user?.email ?? '',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
