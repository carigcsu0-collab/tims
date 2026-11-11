import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/receiving/providers/receiving_provider.dart';

/// Receiving page for recording received goods from purchase orders.
class ReceivingPage extends ConsumerStatefulWidget {
  const ReceivingPage({super.key});

  @override
  ConsumerState<ReceivingPage> createState() => _ReceivingPageState();
}

class _ReceivingPageState extends ConsumerState<ReceivingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receivingNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receivingNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Receiving')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Receiving',
                subtitle: 'Record goods received from purchase orders',
                icon: Icons.inbox,
              ),
              Expanded(
                child: _buildBody(state),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            context.showSnackBar('New receiving record - coming soon'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ReceivingState state) {
    if (state is ReceivingLoading || state is ReceivingInitial) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is ReceivingError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(receivingNotifierProvider.notifier).refresh(),
      );
    }
    if (state is ReceivingLoaded) {
      if (state.receivings.isEmpty) {
        return const EmptyState(
          icon: Icons.inbox_outlined,
          title: 'No Receiving Records',
          message: 'Received goods will appear here once recorded.',
        );
      }
      return ListView.separated(
        itemCount: state.receivings.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final rec = state.receivings[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.inbox)),
            title: Text(rec.receivingNumber),
            subtitle: Text('Date: ${rec.receivedDate}${rec.notes != null ? ' - ${rec.notes}' : ''}'),
            trailing: Text('${rec.items.length} items'),
            onTap: () => context.showSnackBar('Receiving detail - coming soon'),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
