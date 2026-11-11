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
import 'package:tims/features/items/widgets/item_form_dialog.dart';

/// Items page showing a full list of inventory items.
class ItemsPage extends ConsumerStatefulWidget {
  const ItemsPage({super.key});

  @override
  ConsumerState<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends ConsumerState<ItemsPage> {
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
      appBar: AppBar(title: const Text('Items')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Items',
                subtitle: 'Manage all inventory items',
                icon: Icons.widgets,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search items by name or SKU...',
                onChanged: (value) =>
                    ref.read(itemsNotifierProvider.notifier).setSearch(value),
              ),
              const SizedBox(height: 12),
              _buildFilters(context),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: _buildBody(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Future<void> _openForm([ItemModel? item]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ItemFormDialog(item: item),
    );
    if (saved == true && mounted) {
      context.showSnackBar(item == null ? 'Item added' : 'Item updated');
    }
  }

  void _applyFilters({
    String? type,
    String? condition,
    int? qualificationId,
    bool? lowStockOnly,
    bool clearType = false,
    bool clearCondition = false,
    bool clearQualification = false,
  }) {
    final n = ref.read(itemsNotifierProvider.notifier);
    n.setFilters(
      type: clearType ? null : (type ?? n.typeFilter),
      condition: clearCondition ? null : (condition ?? n.conditionFilter),
      qualificationId:
          clearQualification ? null : (qualificationId ?? n.qualificationFilter),
      lowStockOnly: lowStockOnly ?? n.lowStockOnly,
    );
  }

  Widget _buildFilters(BuildContext context) {
    // Re-read when the list state changes so selections stay in sync.
    ref.watch(itemsNotifierProvider);
    final n = ref.read(itemsNotifierProvider.notifier);
    final qualifications = ref.watch(qualificationsProvider).valueOrNull ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final entry in const {
          'tool': 'Tools',
          'equipment': 'Equipment',
          'consumable': 'Consumables',
          'material': 'Materials',
        }.entries)
          FilterChip(
            label: Text(entry.value),
            selected: n.typeFilter == entry.key,
            onSelected: (sel) => sel
                ? _applyFilters(type: entry.key)
                : _applyFilters(clearType: true),
          ),
        FilterChip(
          avatar: const Icon(Icons.warning_amber, size: 16),
          label: const Text('Low stock'),
          selected: n.lowStockOnly,
          onSelected: (sel) => _applyFilters(lowStockOnly: sel),
        ),
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<String?>(
            initialValue: n.conditionFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Condition',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('All')),
              for (final c in ItemCondition.values)
                DropdownMenuItem<String?>(
                  value: c.apiValue,
                  child: Text(c.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => v == null
                ? _applyFilters(clearCondition: true)
                : _applyFilters(condition: v),
          ),
        ),
        SizedBox(
          width: 230,
          child: DropdownButtonFormField<int?>(
            initialValue: n.qualificationFilter,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Qualification',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('All')),
              for (final q in qualifications)
                DropdownMenuItem<int?>(
                  value: q.id,
                  child: Text(q.code, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => v == null
                ? _applyFilters(clearQualification: true)
                : _applyFilters(qualificationId: v),
          ),
        ),
      ],
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
          icon: Icons.widgets_outlined,
          title: 'No Items Found',
          message: 'Add your first inventory item to get started.',
          actionLabel: 'Add Item',
        );
      }
      return _buildItemList(context, state);
    }
    return const SizedBox.shrink();
  }

  Widget _buildItemList(BuildContext context, ItemsLoaded state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200 &&
            state.hasMore) {
          ref.read(itemsNotifierProvider.notifier).loadMore();
        }
        return false;
      },
      child: ListView.separated(
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = state.items[index];
          return _buildItemTile(context, item);
        },
      ),
    );
  }

  Widget _buildItemTile(BuildContext context, ItemModel item) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colorScheme.primaryContainer,
        child: Icon(
          item.type == ItemType.consumable ? Icons.category : Icons.build,
          color: context.colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        item.name,
        style: context.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      hoverColor: context.colorScheme.primary.withValues(alpha: 0.06),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SKU: ${item.sku} | ${item.type.label}'
            '${item.qualificationCode != null ? ' | ${item.qualificationCode}' : ''}',
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Qty: ${FormatHelper.quantity(item.quantity, item.unit)}'
                '${item.isConsumable ? ' (min ${item.minimumStock})' : ''}',
                style: context.textTheme.bodySmall,
              ),
              StatusBadge.fromLabel(item.status.label),
              StatusBadge.fromLabel(item.condition.label),
              if (item.isConsumable && item.belowMinimum)
                const StatusBadge(
                  label: 'Restock needed',
                  status: StatusBadgeType.error,
                ),
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
      onTap: () => _openForm(item),
    );
  }
}
