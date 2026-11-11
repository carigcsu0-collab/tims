import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:tims/app/services/providers.dart';
import 'package:tims/app/widgets/error_display.dart';
import 'package:tims/core/api/api_endpoints.dart';
import 'package:tims/features/items/providers/items_provider.dart';
import 'package:tims/features/reports/services/report_export_service.dart';

enum TvetReportKind {
  inventorySummary('Inventory Summary Report', ApiEndpoints.reportsInventorySummary),
  condition('Status / Condition Report', ApiEndpoints.reportsCondition),
  issuance('Stock-Out / Issuance Report', ApiEndpoints.reportsIssuance);

  const TvetReportKind(this.label, this.endpoint);
  final String label;
  final String endpoint;
}

/// Previews a TVET report and exports it to PDF or Excel-compatible CSV.
class TvetReportPage extends ConsumerStatefulWidget {
  const TvetReportPage({required this.kind, super.key});
  final TvetReportKind kind;

  @override
  ConsumerState<TvetReportPage> createState() => _TvetReportPageState();
}

class _TvetReportPageState extends ConsumerState<TvetReportPage> {
  static const _exporter = ReportExportService();

  int? _qualificationId;
  String? _type;
  String? _condition;
  DateTimeRange? _range;

  TabularReport? _report;
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final res = await ref.read(apiClientProvider).get(
        widget.kind.endpoint,
        queryParameters: {
          if (_qualificationId != null) 'qualification_id': _qualificationId,
          if (_type != null) 'type': _type,
          if (_condition != null) 'condition': _condition,
          if (_range != null) 'date_from': fmt.format(_range!.start),
          if (_range != null) 'date_to': fmt.format(_range!.end),
        },
      );
      if (!mounted) return;
      setState(() =>
          _report = TabularReport.fromJson(res.data as Map<String, dynamic>));
    } on Exception catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<Object?> Function() action, {String? ok}) async {
    try {
      await action();
      if (ok != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final quals = ref.watch(qualificationsProvider).valueOrNull ?? const [];
    final report = _report;

    return Scaffold(
      appBar: AppBar(
        title: Text(kind.label),
        actions: [
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: report == null
                ? null
                : () => _run(() => _exporter.sharePdf(report)),
          ),
          IconButton(
            tooltip: 'Print',
            icon: const Icon(Icons.print),
            onPressed: report == null
                ? null
                : () => _run(() => _exporter.printPdf(report)),
          ),
          IconButton(
            tooltip: 'Export Excel/CSV',
            icon: const Icon(Icons.table_view),
            onPressed: report == null
                ? null
                : () => _run(() => _exporter.saveCsv(report), ok: 'CSV saved'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _qualificationId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                        labelText: 'Qualification / Program',
                        border: OutlineInputBorder(),
                        isDense: true),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      for (final q in quals)
                        DropdownMenuItem(
                            value: q.id,
                            child: Text(q.code, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (v) {
                      _qualificationId = v;
                      _load();
                    },
                  ),
                ),
                if (kind == TvetReportKind.inventorySummary)
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          isDense: true),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(value: 'tool', child: Text('Tools')),
                        DropdownMenuItem(
                            value: 'equipment', child: Text('Equipment')),
                        DropdownMenuItem(
                            value: 'consumable', child: Text('Consumables')),
                        DropdownMenuItem(
                            value: 'material', child: Text('Materials')),
                      ],
                      onChanged: (v) {
                        _type = v;
                        _load();
                      },
                    ),
                  ),
                if (kind == TvetReportKind.condition)
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _condition,
                      decoration: const InputDecoration(
                          labelText: 'Condition',
                          border: OutlineInputBorder(),
                          isDense: true),
                      items: const [
                        DropdownMenuItem(value: null, child: Text('All')),
                        DropdownMenuItem(
                            value: 'needs_repair', child: Text('Needs Repair')),
                        DropdownMenuItem(
                            value: 'condemned', child: Text('Condemned')),
                        DropdownMenuItem(
                            value: 'missing', child: Text('Missing')),
                      ],
                      onChanged: (v) {
                        _condition = v;
                        _load();
                      },
                    ),
                  ),
                if (kind == TvetReportKind.issuance) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    label: Text(_range == null
                        ? 'Date range'
                        : '${DateFormat.yMMMd().format(_range!.start)} â€“ ${DateFormat.yMMMd().format(_range!.end)}'),
                    onPressed: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        initialDateRange: _range,
                      );
                      if (picked != null) {
                        _range = picked;
                        _load();
                      }
                    },
                  ),
                  if (_range != null)
                    TextButton(
                      onPressed: () {
                        _range = null;
                        _load();
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Expanded(child: ErrorDisplay(message: _error!, onRetry: _load))
          else if (report != null)
            Expanded(child: _ReportTable(report: report)),
        ],
      ),
    );
  }
}

class _ReportTable extends StatelessWidget {
  const _ReportTable({required this.report});
  final TabularReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final e in report.summary.entries)
              Chip(label: Text('${e.key}: ${e.value}')),
          ],
        ),
        const SizedBox(height: 8),
        if (report.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No records found.')),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStatePropertyAll(theme.colorScheme.primaryContainer),
              columns: [
                for (final c in report.columns) DataColumn(label: Text(c)),
              ],
              rows: [
                for (final r in report.rows)
                  DataRow(cells: [for (final v in r) DataCell(Text(v))]),
              ],
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
