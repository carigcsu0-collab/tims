import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/core/models/return_model.dart';
import 'package:tims/features/returns/pages/return_detail_page.dart';
import 'package:tims/features/returns/providers/returns_provider.dart';
import 'package:tims/features/returns/widgets/return_form_dialog.dart';

/// Returns page for recording returned borrowed items.
class ReturnsPage extends ConsumerStatefulWidget {
  const ReturnsPage({super.key});

  @override
  ConsumerState<ReturnsPage> createState() => _ReturnsPageState();
}

class _ReturnsPageState extends ConsumerState<ReturnsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(returnsNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(returnsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Returns')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Returns',
                subtitle: 'Record returned borrowed items and their condition',
                icon: Icons.undo,
              ),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showReturnFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ReturnsState state) {
    if (state is ReturnsLoading || state is ReturnsInitial) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is ReturnsError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(returnsNotifierProvider.notifier).refresh(),
      );
    }
    if (state is ReturnsLoaded) {
      if (state.returns.isEmpty) {
        return const EmptyState(
          icon: Icons.undo_outlined,
          title: 'No Return Records',
          message: 'Returned items will appear here once recorded.',
        );
      }
      return ListView.separated(
        itemCount: state.returns.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final ret = state.returns[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.undo)),
            title: Text(ret.returnNumber),
            subtitle: Text('Date: ${ret.returnDate} - Qty: ${ret.quantity}${ret.condition != null ? ' (${ret.condition!.label})' : ''}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReturnDetailPage(returnId: ret.id),
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
