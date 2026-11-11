import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/suppliers/providers/suppliers_provider.dart';

/// Suppliers page for managing supplier records.
class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(suppliersNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(suppliersNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Suppliers',
                subtitle: 'Manage supplier information and contacts',
                icon: Icons.local_shipping,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search suppliers...',
                onChanged: (value) => ref
                    .read(suppliersNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.showSnackBar('Add supplier - coming soon'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SuppliersState state) {
    if (state is SuppliersLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is SuppliersError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(suppliersNotifierProvider.notifier).refresh(),
      );
    }
    if (state is SuppliersLoaded) {
      if (state.suppliers.isEmpty) {
        return const EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'No Suppliers',
          message: 'Add your first supplier to get started.',
        );
      }
      return ListView.separated(
        itemCount: state.suppliers.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final supplier = state.suppliers[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.business,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              supplier.name,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (supplier.contactPerson != null)
                  Text('Contact: ${supplier.contactPerson}'),
                if (supplier.phone != null) Text('Phone: ${supplier.phone}'),
              ],
            ),
            trailing: StatusBadge.fromLabel(
              supplier.isActive ? 'Active' : 'Inactive',
            ),
            onTap: () => context.showSnackBar(
                'Supplier detail for ${supplier.name} - coming soon'),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
