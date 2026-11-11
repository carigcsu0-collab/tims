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
import 'package:tims/features/procurement/providers/purchase_requests_provider.dart';

/// Purchase requests page.
class PurchaseRequestsPage extends ConsumerStatefulWidget {
  const PurchaseRequestsPage({super.key});

  @override
  ConsumerState<PurchaseRequestsPage> createState() =>
      _PurchaseRequestsPageState();
}

class _PurchaseRequestsPageState extends ConsumerState<PurchaseRequestsPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseRequestsNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(purchaseRequestsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Requests')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Purchase Requests',
                subtitle: 'Manage procurement requests',
                icon: Icons.request_quote,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search purchase requests...',
                onChanged: (value) => ref
                    .read(purchaseRequestsNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.showSnackBar('Create purchase request - coming soon'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PurchaseRequestsState state) {
    if (state is PurchaseRequestsLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is PurchaseRequestsError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(purchaseRequestsNotifierProvider.notifier).refresh(),
      );
    }
    if (state is PurchaseRequestsLoaded) {
      if (state.items.isEmpty) {
        return const EmptyState(
          icon: Icons.request_quote_outlined,
          title: 'No Purchase Requests',
          message: 'Create your first purchase request.',
        );
      }
      return ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final pr = state.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.request_quote,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              pr.prNumber,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Requested by: ${pr.requestedByName}'),
                Text(
                  'Date: ${DateHelper.formatDate(pr.createdAt)} | '
                  '${pr.items.length} items',
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  FormatHelper.currency(pr.totalAmount),
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge.fromLabel(pr.status.label),
              ],
            ),
            onTap: () => context.showSnackBar(
                'PR detail for ${pr.prNumber} - coming soon'),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
