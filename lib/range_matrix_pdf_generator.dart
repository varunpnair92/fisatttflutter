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
    'L1','L2','L3','L4','L5','L6','L7','L8','L9','PG LAB'
  ];

  static final Map<String, String> displayName = {"PG LAB": "PG"};

  static const List<int> hourOrder = [1, 2, 3, 4, 8, 5, 6, 7];

  static String formatBlock(List<int> block) {
    String label(int h) => h == 8 ? "LB" : h.toString();
    if (block.length == 1) return label(block.first);
    return "${label(block.first)} To ${label(block.last)}";
  }

  static bool matchFilter(dynamic value, String filter) {
    final ext = (value ?? "").toString().toLowerCase();
    final isExternal = ext.contains("yes") || ext.contains("external");

    if (filter == "external") return isExternal;
    if (filter == "internal") return !isExternal;
    return true;
  }

  static Future<void> generate({
    required DateTime startDate,
    required DateTime endDate,
    required LabController labController,
    required String filter,
  }) async {
    try {
      /// ✅ LOAD FONT
      final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final pdf = pw.Document();
      final df = DateFormat('dd-MM-yyyy');

      print("========== PDF DEBUG ==========");
      labController.labAllotmentsR.forEach((lab, list) {
        print("$lab -> ${list.length}");
      });

      /// DATE LIST
      List<DateTime> dates = [];
      DateTime d = startDate;
      while (!d.isAfter(endDate)) {
        dates.add(d);
        d = d.add(const Duration(days: 1));
      }

      /// MATRIX
      final matrix = <String, Map<String, List<Map<String, dynamic>>>>{};

      for (final date in dates) {
        final dateStr = df.format(date);
        matrix[dateStr] = {};

        print("\n📅 $dateStr");

        for (final lab in labOrder) {
          final allAllotments =
              (labController.labAllotmentsR[lab] ?? [])
                  .cast<Map<String, dynamic>>();

          final filtered = allAllotments.where((e) {
            return (e['date'] ?? '').toString().trim() == dateStr;
          }).toList();

          print("LAB $lab -> ${filtered.length}");

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

      /// ================= PDF =================

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
                style: pw.TextStyle(
                    font: ttf,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold)),

            pw.SizedBox(height: 10),

            pw.Text("From: ${df.format(startDate)}  To: ${df.format(endDate)}",
                style: pw.TextStyle(font: ttf)),

            pw.SizedBox(height: 10),

            /// HEADER
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

            /// ROWS
            ...matrix.entries.map((dateEntry) {

              final labBlocks = <String, List<Map<String, dynamic>>>{};
              int maxBlocks = 1;

              for (var lab in labOrder) {
                final todays =
                    (dateEntry.value[lab] ?? []).cast<Map<String, dynamic>>();

                final blocks = _buildBlocksForLab(todays);
                labBlocks[lab] = blocks;
                if (blocks.length > maxBlocks) maxBlocks = blocks.length;
              }

              final rowHeight = maxBlocks * 22.0;

              return pw.Row(children: [

                pw.Container(
                  width: dateColWidth,
                  height: rowHeight < 90 ? 90 : rowHeight,
                  alignment: pw.Alignment.center,
                  decoration: border,
                  child: pw.Text(dateEntry.key,
                      style: pw.TextStyle(font: ttf)),
                ),

                ...labOrder.map((lab) {

                  final blocks = labBlocks[lab]!;

                  return pw.Container(
                    width: labColWidth,
                    height: rowHeight < 90 ? 90 : rowHeight,
                    padding: const pw.EdgeInsets.all(3),
                    decoration: border,
                    child: pw.Column(
                      children: blocks.map((b) {

                        final entries = b["entries"];
                        final hours = (b["hours"] as List).cast<int>();
                        final isFree = entries.isEmpty;

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

                        print("BLOCK: $text");

                        return pw.Container(
                          padding: const pw.EdgeInsets.all(3),
                          margin: const pw.EdgeInsets.only(bottom: 3),
                          color: color,
                          child: pw.Text(text,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(font: ttf)),
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
      print("❌ PDF ERROR: $e");
    }
  }

  // ================= UTIL =================

  static List<int> _parseHours(dynamic value) {
    if (value == null) return [];
    return value
        .toString()
        .split(',')
        .map((e) => e.trim().toLowerCase() == 'lb'
            ? 8
            : int.tryParse(e.trim()) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  static List<int> _normalizeHours(List<int> hours) {
    final unique = hours.toSet().toList();
    unique.sort((a, b) => hourOrder.indexOf(a).compareTo(hourOrder.indexOf(b)));
    return unique;
  }

  static bool _same(List a, List b) {
    if (a.length != b.length) return false;

    List<String> ak = a
        .map((e) =>
            "${e['class_name']}_${e['subject_name']}_${e['external']}_${e['hours']}")
        .toList()
      ..sort();

    List<String> bk = b
        .map((e) =>
            "${e['class_name']}_${e['subject_name']}_${e['external']}_${e['hours']}")
        .toList()
      ..sort();

    return ak.toString() == bk.toString();
  }

  static List<Map<String, dynamic>> _buildBlocksForLab(
      List<Map<String, dynamic>> todays) {

    Map<int, List<Map<String, dynamic>>> hourMap = {
      for (var h in hourOrder) h: []
    };

    for (var e in todays) {
      for (var h in e['hours']) {
        hourMap[h]!.add(e);
      }
    }

    List<Map<String, dynamic>> blocks = [];

    List currentEntries = [];
    List<int> currentHours = [];

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