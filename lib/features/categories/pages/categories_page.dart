import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/empty_state.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/loading_widgets.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/app/widgets/search_bar_widget.dart';
import 'package:tims/app/widgets/status_badge.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/categories/providers/categories_provider.dart';
import 'package:tims/features/categories/widgets/category_form_dialog.dart';

/// Categories page for managing inventory categories.
class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoriesNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: SafeArea(
        child: Padding(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Categories',
                subtitle: 'Organize inventory items into categories',
                icon: Icons.category,
              ),
              SearchBarWidget(
                controller: _searchController,
                hint: 'Search categories...',
                onChanged: (value) => ref
                    .read(categoriesNotifierProvider.notifier)
                    .setSearch(value),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryFormDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CategoriesState state) {
    if (state is CategoriesLoading) {
      return ListView.builder(
        itemCount: 6,
        itemBuilder: (_, _) => const LoadingListTile(),
      );
    }
    if (state is CategoriesError) {
      return ErrorDisplay(
        message: state.message,
        onRetry: () =>
            ref.read(categoriesNotifierProvider.notifier).refresh(),
      );
    }
    if (state is CategoriesLoaded) {
      if (state.categories.isEmpty) {
        return const EmptyState(
          icon: Icons.category_outlined,
          title: 'No Categories',
          message: 'Create your first inventory category.',
        );
      }
      return ListView.separated(
        itemCount: state.categories.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final category = state.categories[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: context.colorScheme.primaryContainer,
              child: Icon(
                Icons.folder_outlined,
                color: context.colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              category.name,
              style: context.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              category.code != null
                  ? 'Code: ${category.code} | ${category.itemCount} items'
                  : '${category.itemCount} items',
            ),
            trailing: StatusBadge.fromLabel(
              category.isActive ? 'Active' : 'Inactive',
            ),
            onTap: () => showCategoryFormDialog(context, category: category),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
