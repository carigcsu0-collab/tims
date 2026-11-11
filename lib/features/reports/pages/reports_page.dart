import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tims/app/widgets/animated_widgets.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/app/widgets/page_header.dart';
import 'package:tims/core/extensions/context_extensions.dart';
import 'package:tims/features/reports/pages/tvet_report_page.dart';
import 'package:tims/features/reports/providers/reports_provider.dart';

/// Reports page for generating and viewing inventory reports.
class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final reportTypes = [
      _ReportType(
        icon: Icons.account_tree,
        title: 'Inventory Summary',
        description: 'Tools, equipment & consumables by training program',
        color: isDark ? Colors.green.shade300 : Colors.green,
        type: 'tvet:inventorySummary',
      ),
      _ReportType(
        icon: Icons.build_circle,
        title: 'Status / Condition',
        description: 'Defective, missing, condemned or needs-repair items',
        color: isDark ? Colors.red.shade300 : Colors.red,
        type: 'tvet:condition',
      ),
      _ReportType(
        icon: Icons.outbox,
        title: 'Stock-Out / Issuance',
        description: 'Items issued to trainers and assessors',
        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
        type: 'tvet:issuance',
      ),
      _ReportType(
        icon: Icons.inventory,
        title: 'Inventory Report',
        description: 'Complete inventory valuation and stock levels',
        color: isDark ? Colors.blue.shade300 : Colors.blue,
        type: 'inventory',
      ),
      _ReportType(
        icon: Icons.request_quote,
        title: 'Procurement Report',
        description: 'Purchase requests and orders summary',
        color: isDark ? Colors.purple.shade300 : Colors.purple,
        type: 'procurement',
      ),
      _ReportType(
        icon: Icons.swap_horiz,
        title: 'Borrowing Report',
        description: 'Borrowing transactions and overdue items',
        color: isDark ? Colors.orange.shade300 : Colors.orange,
        type: 'borrowing',
      ),
      _ReportType(
        icon: Icons.build,
        title: 'Maintenance Report',
        description: 'Maintenance schedules and costs',
        color: isDark ? Colors.teal.shade300 : Colors.teal,
        type: 'maintenance',
      ),
      _ReportType(
        icon: Icons.fact_check,
        title: 'Audit Report',
        description: 'Inventory audit results and discrepancies',
        color: isDark ? Colors.indigo.shade300 : Colors.indigo,
        type: 'audit',
      ),
      _ReportType(
        icon: Icons.trending_down,
        title: 'Stock Movement Report',
        description: 'All stock movements and adjustments',
        color: isDark ? Colors.brown.shade300 : Colors.brown,
        type: 'stock_movement',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: context.responsivePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Reports',
                subtitle: 'Generate and export inventory reports',
                icon: Icons.assessment,
              ),
              if (state is ReportsLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (state is ReportsError)
                ErrorDisplay(
                  message: state.message,
                  onRetry: () {
                    if (state.reportType != null) {
                      ref
                          .read(reportsNotifierProvider.notifier)
                          .generateReport(state.reportType!);
                    }
                  },
                ),
              if (state is ReportsLoaded)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Report generated: ${state.reportType}',
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: reportTypes.length,
                itemBuilder: (context, index) {
                  final report = reportTypes[index];
                  return FadeSlideIn.staggered(
                    index: index,
                    child: Card(
                    child: InkWell(
                      onTap: () {
                        if (report.type.startsWith('tvet:')) {
                          final kind = TvetReportKind.values.byName(
                              report.type.substring('tvet:'.length));
                          Navigator.of(context).push(MaterialPageRoute<void>(
                              builder: (_) => TvetReportPage(kind: kind)));
                          return;
                        }
                        ref
                            .read(reportsNotifierProvider.notifier)
                            .generateReport(report.type);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: report.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(report.icon,
                                  color: report.color, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              report.title,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              report.description,
                              style: context.textTheme.bodySmall?.copyWith(
                                color:
                                    context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportType {
  const _ReportType({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.type,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String type;
}
