import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/helpers/format_helper.dart';
import 'package:tims/core/models/item_model.dart';
import 'package:tims/features/items/providers/items_provider.dart';

/// Inventory overview page showing all inventory items with filtering.
class InventoryPage extends ConsumerStatefulWidget {
  const InventoryPage({super.key});

  @override
  ConsumerState<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends ConsumerState<InventoryPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemsNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Inventory',
                subtitle: 'Manage all tools, equipment, and consumables',
                icon: Icons.inventory_2,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search inventory...',
                onChanged: (value) =>
                    ref.read(itemsNotifierProvider.notifier).setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.showSnackBar('Add item - coming soon'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ItemsState state) {
    if (state is ItemsLoading) {
      return ListView.builder(
        itemCount: 8,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is ItemsError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () => ref.read(itemsNotifierProvider.notifier).refresh(),
      );
    }
    if (state is ItemsLoaded) {
      if (state.items.isEmpty) {
        return const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No Items Found',
          message: 'Start by adding your first inventory item.',
        );
      }
      return _buildItemList(context, state.items);
    }
    return const SizedBox.shrink();
  }

  Widget _buildItemList(BuildContext context, List<ItemModel> items) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: context.colorScheme.primaryContainer,
            child: Icon(
              item.type == ItemType.consumable
                  ? Icons.category
                  : Icons.build,
              color: context.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            item.name,
            style: context.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SKU: ${item.sku}'),
              Row(
                children: [
                  Text(
                    'Qty: ${FormatHelper.quantity(item.quantity, item.unit)}',
                    style: context.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  StatusBadge.fromLabel(item.status.label),
                ],
              ),
            ],
          ),
          trailing: Text(
            FormatHelper.currency(item.unitCost),
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: () {
            context.showSnackBar(
                'Item detail for ${item.name} - coming soon');
          },
        );
      },
    );
  }
}
