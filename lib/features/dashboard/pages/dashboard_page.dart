import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import 'package:tims/app/routes/route_paths.dart';
import 'package:tims/app/services/providers.dart';
import 'package:tims/app/widgets/animated_widgets.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/stat_card.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/dashboard_stats_model.dart';
import 'package:tims/features/dashboard/providers/dashboard_provider.dart';

/// Warns about consumables that reached their minimum restock threshold.
class _LowStockAlertCard extends StatelessWidget {
  const _LowStockAlertCard({required this.alerts, required this.onViewAll});

  final List<LowStockAlert> alerts;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = alerts.take(6).toList();

    return FadeSlideIn(
      child: Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Pulse(
                  child: Icon(Icons.warning_amber_rounded,
                      color: theme.colorScheme.error),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Restock needed: ${alerts.length} consumable(s) at or below minimum',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: onViewAll, child: const Text('View items')),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in shown)
                  Chip(
                    avatar: Icon(
                      a.isOutOfStock ? Icons.error : Icons.warning,
                      size: 16,
                      color: a.isOutOfStock ? Colors.red : Colors.orange,
                    ),
                    label: Text(
                      '${a.name}${a.qualificationCode != null ? ' (${a.qualificationCode})' : ''}: '
                      '${a.quantity}/${a.minimumStock} ${a.unit}',
                    ),
                  ),
                if (alerts.length > shown.length)
                  Chip(label: Text('+${alerts.length - shown.length} more')),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Dashboard page showing overview statistics and quick actions.
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardNotifierProvider);
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardNotifierProvider.notifier).loadStats(),
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Welcome, ${user?.name.split(' ').first ?? 'User'}',
                  subtitle:
                      'Here\'s an overview of your inventory system today.',
                ),
                _buildBody(context, state),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state is DashboardLoading || state is DashboardInitial) {
      return StaggeredGrid.count(
        crossAxisCount: context.isDesktop ? 4 : context.isTablet ? 2 : 1,
        children: List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LoadingCard(),
          ),
        ),
      );
    }

    if (state is DashboardError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(dashboardNotifierProvider.notifier).loadStats(),
      );
    }

    if (state is DashboardLoaded) {
      return _buildStats(context, state.stats);
    }

    return const SizedBox.shrink();
  }

  Widget _buildStats(BuildContext context, DashboardStatsModel stats) {
    final crossAxisCount =
        context.isDesktop ? 4 : context.isTablet ? 2 : 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.lowStockConsumables.isNotEmpty) ...[
          _LowStockAlertCard(
            alerts: stats.lowStockConsumables,
            onViewAll: () => context.go(RoutePaths.items),
          ),
          const SizedBox(height: 16),
        ],
        _buildStatGrid(context, stats, crossAxisCount, isDark),
      ],
    );
  }

  Widget _buildStatGrid(BuildContext context, DashboardStatsModel stats,
      int crossAxisCount, bool isDark) {
    return StaggeredGrid.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: _stagger([
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Items',
            value: FormatHelper.number(stats.totalItems),
            icon: Icons.inventory_2,
            onTap: () => context.go(RoutePaths.items),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Tools & Equipment',
            value: FormatHelper.number(stats.totalTools + stats.totalEquipment),
            icon: Icons.build,
            color: isDark ? Colors.indigo.shade300 : Colors.indigo,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Needs Repair',
            value: FormatHelper.number(stats.needsRepairCount),
            icon: Icons.handyman,
            color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
            subtitle:
                '${stats.condemnedCount} condemned · ${stats.missingCount} missing',
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Consumables',
            value: FormatHelper.number(stats.totalConsumables),
            icon: Icons.category,
            color: isDark ? Colors.teal.shade300 : Colors.teal,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Total Value',
            value: FormatHelper.currency(stats.totalValue),
            icon: Icons.attach_money,
            color: isDark ? Colors.green.shade300 : Colors.green,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Low Stock',
            value: FormatHelper.number(stats.lowStockCount),
            icon: Icons.warning,
            color: isDark ? Colors.orange.shade300 : Colors.orange,
            subtitle: 'Items need restocking',
            onTap: () => context.go(RoutePaths.items),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Out of Stock',
            value: FormatHelper.number(stats.outOfStockCount),
            icon: Icons.error_outline,
            color: isDark ? Colors.red.shade300 : Colors.red,
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Pending PRs',
            value: FormatHelper.number(stats.pendingPurchaseRequests),
            icon: Icons.request_quote,
            color: isDark ? Colors.purple.shade300 : Colors.purple,
            onTap: () => context.go(RoutePaths.purchaseRequests),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Active Borrowings',
            value: FormatHelper.number(stats.activeBorrowings),
            icon: Icons.swap_horiz,
            color: isDark ? Colors.blue.shade300 : Colors.blue,
            onTap: () => context.go(RoutePaths.borrowing),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Pending Maintenance',
            value: FormatHelper.number(stats.pendingMaintenance),
            icon: Icons.build_outlined,
            color: isDark ? Colors.deepOrange.shade300 : Colors.deepOrange,
            onTap: () => context.go(RoutePaths.maintenance),
          ),
        ),
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: StatCard(
            title: 'Suppliers',
            value: FormatHelper.number(stats.totalSuppliers),
            icon: Icons.local_shipping,
            color: isDark ? Colors.brown.shade300 : Colors.brown,
            onTap: () => context.go(RoutePaths.suppliers),
          ),
        ),
      ]),
    );
  }

  List<Widget> _stagger(List<StaggeredGridTile> tiles) => [
        for (var i = 0; i < tiles.length; i++)
          StaggeredGridTile.fit(
            crossAxisCellCount: tiles[i].crossAxisCellCount,
            child: FadeSlideIn.staggered(index: i, child: tiles[i].child),
          ),
      ];
}
