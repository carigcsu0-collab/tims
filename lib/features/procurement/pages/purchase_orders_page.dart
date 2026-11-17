import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/date_helper.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/features/procurement/providers/purchase_orders_provider.dart';
import 'package:tims/features/procurement/widgets/purchase_order_detail_dialog.dart';
import 'package:tims/features/procurement/widgets/purchase_order_form_dialog.dart';

/// Purchase orders page.
class PurchaseOrdersPage extends ConsumerStatefulWidget {
  const PurchaseOrdersPage({super.key});

  @override
  ConsumerState<PurchaseOrdersPage> createState() =>
      _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends ConsumerState<PurchaseOrdersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseOrdersNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseOrdersNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Orders')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Purchase Orders',
                subtitle: 'Manage purchase orders',
                icon: Icons.receipt_long,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search purchase orders...',
                onChanged: (value) => ref
                    .read(purchaseOrdersNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showPurchaseOrderFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PurchaseOrdersState state) {
    if (state is PurchaseOrdersLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is PurchaseOrdersError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(purchaseOrdersNotifierProvider.notifier).refresh(),
      );
    }
    if (state is PurchaseOrdersLoaded) {
      if (state.items.isEmpty) {
        return const EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'No Purchase Orders',
          message: 'Create your first purchase order.',
        );
      }
      return ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final po = state.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.receipt_long,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              po.poNumber,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expected: ${DateHelper.formatDate(po.expectedDeliveryDate)} | '
                  '${po.items.length} items',
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatHelper.currency(po.totalAmount),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge.fromLabel(po.status.label),
              ],
            ),
            onTap: () => showPurchaseOrderDetailDialog(context, po),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
