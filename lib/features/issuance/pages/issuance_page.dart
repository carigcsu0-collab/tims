import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/issuance/providers/issuance_provider.dart';

/// Issuance page for recording items issued to departments/personnel.
class IssuancePage extends ConsumerStatefulWidget {
  const IssuancePage({super.key});

  @override
  ConsumerState<IssuancePage> createState() => _IssuancePageState();
}

class _IssuancePageState extends ConsumerState<IssuancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(issuanceNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(issuanceNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Issuance')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Issuance',
                subtitle: 'Record items issued to departments and personnel',
                icon: Icons.outbox,
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
            context.showSnackBar('New issuance record - coming soon'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(IssuanceState state) {
    if (state is IssuanceLoading || state is IssuanceInitial) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is IssuanceError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(issuanceNotifierProvider.notifier).refresh(),
      );
    }
    if (state is IssuanceLoaded) {
      if (state.issuances.isEmpty) {
        return const EmptyState(
          icon: Icons.outbox_outlined,
          title: 'No Issuance Records',
          message: 'Issued items will appear here once recorded.',
        );
      }
      return ListView.separated(
        itemCount: state.issuances.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final iss = state.issuances[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.outbox)),
            title: Text(iss.issuanceNumber),
            subtitle: Text('Date: ${iss.issueDate}${iss.purpose != null ? ' - ${iss.purpose}' : ''}'),
            trailing: Text('${iss.items.length} items'),
            onTap: () => context.showSnackBar('Issuance detail - coming soon'),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
