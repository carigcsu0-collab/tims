import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:tims/app/config/app_config.dart';

/// Tabular report returned by the TVET report endpoints.
class TabularReport {
  const TabularReport({
    required this.title,
    required this.columns,
    required this.rows,
    required this.summary,
  });

  factory TabularReport.fromJson(Map<String, dynamic> json) => TabularReport(
        title: json['title'] as String? ?? 'Report',
        columns: (json['columns'] as List).map((e) => '$e').toList(),
        rows: (json['rows'] as List)
            .map((r) => (r as List).map((e) => '${e ?? ''}').toList())
            .toList(),
        summary: ((json['summary'] as Map?) ?? {})
            .map((k, v) => MapEntry('$k', '$v')),
      );

  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final Map<String, String> summary;
}

class ReportExportService {
  const ReportExportService();

  String _fileStem(TabularReport r) {
    final slug = r.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${slug}_${DateFormat('yyyyMMdd').format(DateTime.now())}';
  }

  Future<Uint8List> buildPdf(TabularReport report) async {
    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load(AppConfig.logoAsset);
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } on Object {
      logo = null; // Logo file not provided yet; header renders without it.
    }

    final generated = DateFormat('MMMM d, y h:mm a').format(DateTime.now());
    final doc = pw.Document();

    pw.Widget header() => pw.Column(children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logo != null) pw.Image(logo, width: 56, height: 56),
              if (logo != null) pw.SizedBox(width: 12),
              pw.Column(children: [
                pw.Text('Republic of the Philippines',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text(AppConfig.universityName,
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                pw.Text(AppConfig.officeName,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ]),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Divider(thickness: 1.5),
          pw.Text(report.title.toUpperCase(),
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.Text('Generated: $generated',
              style: const pw.TextStyle(fontSize: 8)),
          pw.SizedBox(height: 8),
        ]);

    pw.Widget signature() => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 36),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 200,
              child: pw.Column(children: [
                pw.Text('Prepared by:',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 30),
                pw.Container(height: 1, color: PdfColors.black),
                pw.Text('Campus TVET Coordinator',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text('Signature over Printed Name',
                    style: const pw.TextStyle(fontSize: 7)),
                pw.SizedBox(height: 4),
                pw.Text('Date: ____________________',
                    style: const pw.TextStyle(fontSize: 8)),
              ]),
            ),
          ),
        );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      header: (_) => header(),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${c.pageNumber} of ${c.pagesCount}',
            style: const pw.TextStyle(fontSize: 8)),
      ),
      build: (_) => [
        if (report.summary.isNotEmpty)
          pw.Wrap(
            spacing: 18,
            children: report.summary.entries
                .map((e) => pw.Text('${e.key}: ${e.value}',
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)))
                .toList(),
          ),
        pw.SizedBox(height: 8),
        if (report.rows.isEmpty)
          pw.Text('No records found.')
        else
          pw.TableHelper.fromTextArray(
            headers: report.columns,
            data: report.rows,
            headerStyle: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.green800),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(3),
            border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey600),
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        pw.Wrap(children: [signature()]),
      ],
    ));

    return doc.save();
  }

  Future<void> sharePdf(TabularReport report) async {
    final bytes = await buildPdf(report);
    await Printing.sharePdf(bytes: bytes, filename: '${_fileStem(report)}.pdf');
  }

  Future<void> printPdf(TabularReport report) =>
      Printing.layoutPdf(onLayout: (_) => buildPdf(report), name: report.title);

  String buildCsv(TabularReport report) {
    String esc(String v) {
      var s = v;
      // Neutralise spreadsheet formula injection.
      if (s.isNotEmpty && '=+-@'.contains(s[0]) && double.tryParse(s) == null) {
        s = "'$s";
      }
      return '"${s.replaceAll('"', '""')}"';
    }

    final b = StringBuffer()
      ..writeln(esc(AppConfig.universityName))
      ..writeln(esc(AppConfig.officeName))
      ..writeln(esc(report.title))
      ..writeln(esc(
          'Generated: ${DateFormat('y-MM-dd HH:mm').format(DateTime.now())}'))
      ..writeln()
      ..writeln(report.columns.map(esc).join(','));
    for (final r in report.rows) {
      b.writeln(r.map(esc).join(','));
    }
    b
      ..writeln()
      ..writeln('${esc('Prepared by:')},,${esc('Campus TVET Coordinator')}');
    return b.toString();
  }

  /// Saves an Excel-compatible CSV (UTF-8 with BOM). Returns the saved path.
  Future<String?> saveCsv(TabularReport report) {
    final bytes =
        Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(buildCsv(report))]);
    return FilePicker.platform.saveFile(
      dialogTitle: 'Save report',
      fileName: '${_fileStem(report)}.csv',
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
  }
}
