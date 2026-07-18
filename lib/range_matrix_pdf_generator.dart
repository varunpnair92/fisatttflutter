import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'lab_controller.dart';

class RangeMatrixPdfGenerator {
  static final List<String> labOrder = [
    'L1',
    'L2',
    'L3',
    'L4',
    'L5',
    'L6',
    'L7',
    'L8',
    'L9',
    'PG LAB'
  ];

  static final Map<String, String> displayName = {"PG LAB": "PG"};

  static const List<String> hourOrder = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "1.30-3.30"
  ];

  /// ✅ CHANGED: To → -
  static String formatBlock(List<String> block) {
    if (block.length == 1) return block.first;
    return "${block.first}-${block.last}";
  }

  static bool matchFilter(dynamic value, String filter) {
    final ext = (value ?? "").toString().toLowerCase().trim();
    final isExternal = ext.contains("yes") || ext.contains("external");

    if (filter == "external") return isExternal;
    if (filter == "internal") return !isExternal;
    return true;
  }

  static double _estimateBlockHeight(String text) {
    final lines = '\n'.allMatches(text).length + 1;
    return (lines * 12) + 14;
  }

  static Future<void> generate({
    required DateTime startDate,
    required DateTime endDate,
    required LabController labController,
    required String filter,
  }) async {
    try {
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdf = pw.Document();
      final df = DateFormat('dd-MM-yyyy');

      List<DateTime> dates = [];
      DateTime d = startDate;
      while (!d.isAfter(endDate)) {
        dates.add(d);
        d = d.add(const Duration(days: 1));
      }

      final matrix = <String, Map<String, List<Map<String, dynamic>>>>{};

      for (final date in dates) {
        final dateStr = df.format(date);
        matrix[dateStr] = {};

        for (final lab in labOrder) {
          final allAllotments = (labController.labAllotmentsR[lab] ?? [])
              .cast<Map<String, dynamic>>();

          final filtered = allAllotments.where((e) {
            return (e['date'] ?? '').toString().trim() == dateStr;
          }).toList();

          final grouped = <String, Map<String, dynamic>>{};

          for (var e in filtered) {
            if (!matchFilter(e["external"], filter)) continue;

            final key =
                "${e['class_name']}_${e['subject_name']}_${e['external']}_${e['date']}";

            final hours = _parseHours(e["hours"]);
            if (hours.isEmpty) continue;

            grouped[key] = {
              "class_name": e["class_name"],
              "subject_name": e["subject_name"],
              "external": e["external"],
              "hours": _normalizeHours(hours),
            };
          }

          matrix[dateStr]![lab] = grouped.values.toList();
        }
      }

      const blue = PdfColor.fromInt(0xFFADD8E6);
      const green = PdfColor.fromInt(0xFF90EE90);
      const orange = PdfColor.fromInt(0xFFFFCC80);

      final border = pw.BoxDecoration(border: pw.Border.all());

      final pageWidth = PdfPageFormat.a4.landscape.width - 20;
      const dateColWidth = 90.0;
      final labColWidth = (pageWidth - dateColWidth) / labOrder.length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(10),
          build: (_) => [
            pw.Text("LAB ALLOTMENT",
                style: pw.TextStyle(font: ttf, fontSize: 20)),
            pw.SizedBox(height: 10),
            pw.Text(
              "From: ${df.format(startDate)}  To: ${df.format(endDate)}",
              style: pw.TextStyle(font: ttf),
            ),
            pw.SizedBox(height: 10),
            pw.Row(children: [
              pw.Container(
                width: dateColWidth,
                height: 30,
                alignment: pw.Alignment.center,
                decoration: border,
                child: pw.Text("DATE", style: pw.TextStyle(font: ttf)),
              ),
              ...labOrder.map((lab) => pw.Container(
                    width: labColWidth,
                    height: 30,
                    alignment: pw.Alignment.center,
                    decoration: border,
                    child: pw.Text(displayName[lab] ?? lab,
                        style: pw.TextStyle(font: ttf)),
                  )),
            ]),
            pw.SizedBox(height: 5),
            ...matrix.entries.map((dateEntry) {
              final labBlocks = <String, List<Map<String, dynamic>>>{};
              double maxHeight = 80;

              for (var lab in labOrder) {
                final todays =
                    (dateEntry.value[lab] ?? []).cast<Map<String, dynamic>>();

                final blocks = _buildBlocksForLab(todays);
                labBlocks[lab] = blocks;

                double totalHeight = 0;

                for (var b in blocks) {
                  final entries = b["entries"];
                  final hours = (b["hours"] as List).cast<String>();

                  if (filter != "both" && entries.isEmpty) continue;

                  /// ✅ FIX: FREE DETECTION
                  bool isFree = entries.isEmpty ||
                      entries.any((e) =>
                          (e['subject_name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .trim() ==
                              'free' ||
                          (e['class_name'] ?? '')
                                  .toString()
                                  .toLowerCase()
                                  .trim() ==
                              'free');

                  final text = isFree
                      ? "FREE\nHrs: ${formatBlock(hours)}"
                      : entries
                              .map((e) =>
                                  "${e['class_name']}\n${e['subject_name']}")
                              .join("\n\n") +
                          "\nHrs: ${formatBlock(hours)}";

                  totalHeight += _estimateBlockHeight(text) + 4;
                }

                if (totalHeight > maxHeight) maxHeight = totalHeight;
              }

              return pw.Row(children: [
                pw.Container(
                  width: dateColWidth,
                  height: maxHeight,
                  alignment: pw.Alignment.center,
                  decoration: border,
                  child: pw.Text(dateEntry.key, style: pw.TextStyle(font: ttf)),
                ),
                ...labOrder.map((lab) {
                  final blocks = labBlocks[lab]!;

                  return pw.Container(
                    width: labColWidth,
                    height: maxHeight,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: border,
                    child: pw.Column(
                      children: blocks.map((b) {
                        final entries = b["entries"];
                        final hours = (b["hours"] as List).cast<String>();

                        if (filter != "both" && entries.isEmpty) {
                          return pw.SizedBox();
                        }

                        /// ✅ FIX: FREE DETECTION
                        bool isFree = entries.isEmpty ||
                            entries.any((e) =>
                                (e['subject_name'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .trim() ==
                                    'free' ||
                                (e['class_name'] ?? '')
                                        .toString()
                                        .toLowerCase()
                                        .trim() ==
                                    'free');

                        final color = isFree
                            ? orange
                            : ((entries.first["external"] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .contains("external"))
                                ? green
                                : blue;

                        final text = isFree
                            ? "FREE\nHrs: ${formatBlock(hours)}"
                            : entries
                                    .map((e) =>
                                        "${e['class_name']}\n${e['subject_name']}")
                                    .join("\n\n") +
                                "\nHrs: ${formatBlock(hours)}";

                        final height = _estimateBlockHeight(text);

                        return pw.Container(
                          height: height,
                          margin: const pw.EdgeInsets.only(bottom: 4),
                          padding: const pw.EdgeInsets.all(6),
                          color: color,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            text,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(font: ttf, fontSize: 9),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ]);
            }),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          "${dir.path}/lab_usage_matrix_${DateTime.now().millisecondsSinceEpoch}.pdf");

      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      //print("PDF ERROR: $e");
    }
  }

  static List<String> _parseHours(dynamic value) {
    if (value == null) return [];
    return value
        .toString()
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _normalizeHours(List<String> hours) {
    final unique = hours.toSet().toList();
    unique.sort((a, b) => hourOrder.indexOf(a).compareTo(hourOrder.indexOf(b)));
    return unique;
  }

  static bool _same(List a, List b) {
    if (a.length != b.length) return false;

    List<String> ak = a
        .map((e) => "${e['class_name']}_${e['subject_name']}")
        .toList()
      ..sort();

    List<String> bk = b
        .map((e) => "${e['class_name']}_${e['subject_name']}")
        .toList()
      ..sort();

    return ak.toString() == bk.toString();
  }

  static List<Map<String, dynamic>> _buildBlocksForLab(
      List<Map<String, dynamic>> todays) {
    Map<String, List<Map<String, dynamic>>> hourMap = {
      for (var h in hourOrder) h: []
    };

    for (var e in todays) {
      for (var h in e['hours']) {
        hourMap[h]!.add(e);
      }
    }

    List<Map<String, dynamic>> blocks = [];

    List currentEntries = [];
    List<String> currentHours = [];

    for (var h in hourOrder) {
      final entries = hourMap[h]!;

      if (currentHours.isEmpty) {
        currentEntries = List.from(entries);
        currentHours = [h];
        continue;
      }

      if (_same(entries, currentEntries)) {
        currentHours.add(h);
      } else {
        blocks.add({
          'entries': List.from(currentEntries),
          'hours': List.from(currentHours),
        });
        currentEntries = List.from(entries);
        currentHours = [h];
      }
    }

    if (currentHours.isNotEmpty) {
      blocks.add({
        'entries': List.from(currentEntries),
        'hours': List.from(currentHours),
      });
    }

    return blocks;
  }
}
