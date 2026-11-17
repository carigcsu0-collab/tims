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
import 'package:tims/features/borrowing/providers/borrowing_provider.dart';
import 'package:tims/features/borrowing/widgets/borrowing_detail_dialog.dart';
import 'package:tims/features/borrowing/widgets/borrowing_form_dialog.dart';

/// Borrowing page for managing tool/equipment borrowing transactions.
class BorrowingPage extends ConsumerStatefulWidget {
  const BorrowingPage({super.key});

  @override
  ConsumerState<BorrowingPage> createState() => _BorrowingPageState();
}

class _BorrowingPageState extends ConsumerState<BorrowingPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(borrowingNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(borrowingNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Borrowing')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Borrowing',
                subtitle: 'Manage tool and equipment borrowing transactions',
                icon: Icons.swap_horiz,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search borrowings...',
                onChanged: (value) => ref
                    .read(borrowingNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showBorrowingFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BorrowingState state) {
    if (state is BorrowingLoading || state is BorrowingInitial) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is BorrowingError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(borrowingNotifierProvider.notifier).refresh(),
      );
    }
    if (state is BorrowingLoaded) {
      if (state.items.isEmpty) {
        return const EmptyState(
          icon: Icons.swap_horiz_outlined,
          title: 'No Borrowing Records',
          message: 'Create a new borrowing transaction to get started.',
        );
      }
      return ListView.separated(
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final b = state.items[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: b.isOverdue
                  ? context.colorScheme.error.withValues(alpha: 0.15)
                  : context.colorScheme.primaryContainer,
              child: Icon(
                Icons.swap_horiz,
                color: b.isOverdue
                    ? context.colorScheme.error
                    : context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              b.borrowNumber,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Item: ${b.itemName}'),
                Text(
                  'Borrower: ${b.borrowerName} | Qty: ${b.quantity}',
                ),
                Text(
                  'Borrowed: ${DateHelper.formatDate(b.borrowDate)}'
                  '${b.expectedReturnDate != null ? ' | Due: ${DateHelper.formatDate(b.expectedReturnDate)}' : ''}',
                ),
              ],
            ),
            trailing: StatusBadge.fromLabel(b.status.label),
            onTap: () => showBorrowingDetailDialog(context, b),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
