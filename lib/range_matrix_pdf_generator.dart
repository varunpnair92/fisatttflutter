
import 'dart:io';
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

  static const List<int> hourOrder = [1,2,3,4,8,5,6,7];

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
      final pdf = pw.Document();
      final df = DateFormat('dd-MM-yyyy');

      /// DATE LIST
      List<DateTime> dates = [];
      DateTime d = startDate;
      while (!d.isAfter(endDate)) {
        dates.add(d);
        d = d.add(const Duration(days: 1));
      }

      /// MATRIX BUILD
      final matrix = <String, Map<String, List<Map<String, dynamic>>>>{};

      for (final date in dates) {
        final dateStr = df.format(date);
        matrix[dateStr] = {};

        await labController.fetchLabAllotmentsForDate(date);

        for (final lab in labOrder) {

          final allotments = (labController.labAllotments[lab] ?? [])
              .cast<Map<String, dynamic>>();

          final grouped = <String, Map<String, dynamic>>{};

          for (var e in allotments) {

            if (!matchFilter(e["external"], filter)) continue;

            final subj = (e["subject_name"] ?? "").toString().toLowerCase();
            final cls  = (e["class_name"] ?? "").toString().toLowerCase();

            if (subj == "free" || cls == "free") continue;

            final key = "${e['class_name']}_${e['subject_name']}_${e['external']}";

            final hour = int.tryParse(
              e["hours"]?.toString() ??
              e["hours_allotted"]?.toString() ??
              "0"
            ) ?? 0;

            if (!grouped.containsKey(key)) {
              grouped[key] = {
                "class_name": e["class_name"],
                "subject_name": e["subject_name"],
                "external": e["external"],
                "hours": <int>[hour],
              };
            } else {
              (grouped[key]!["hours"] as List<int>).add(hour);
            }
          }

          matrix[dateStr]![lab] = grouped.values.toList();
        }
      }

      const blue   = PdfColor.fromInt(0xFFADD8E6);
      const green  = PdfColor.fromInt(0xFF90EE90);
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
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),

            pw.SizedBox(height: 10),

            pw.Text("From: ${df.format(startDate)}  To: ${df.format(endDate)}"),

            pw.SizedBox(height: 10),

            /// HEADER
            pw.Row(children: [
              pw.Container(
                width: dateColWidth,
                height: 30,
                alignment: pw.Alignment.center,
                decoration: border,
                child: pw.Text("DATE"),
              ),
              ...labOrder.map((lab) => pw.Container(
                width: labColWidth,
                height: 30,
                alignment: pw.Alignment.center,
                decoration: border,
                child: pw.Text(displayName[lab] ?? lab),
              )),
            ]),

            pw.SizedBox(height: 5),

            /// ROWS
            ...matrix.entries.map((dateEntry) {

              int maxBlocks = 1;

              /// FIRST PASS → count blocks
              for (var lab in labOrder) {

                final todays = (dateEntry.value[lab] ?? [])
                    .cast<Map<String, dynamic>>();

                Map<int, List<Map<String, dynamic>>> hourMap = {
                  for (var h in hourOrder) h: []
                };

                for (var e in todays) {
                  final hrs = (e["hours"] as List).cast<int>();
                  for (var h in hrs) {
                    hourMap[h]!.add(e);
                  }
                }

                int count = 0;
                List current = [];

                for (var h in hourOrder) {
                  final entries = hourMap[h]!;

                  if (entries.isEmpty && current.isEmpty) continue;

                  if (!identical(entries, current)) {
                    count++;
                    current = entries;
                  }
                }

                if (count > maxBlocks) maxBlocks = count;
              }

              final rowHeight = maxBlocks * 22.0;

              return pw.Row(children: [

                /// DATE
                pw.Container(
                  width: dateColWidth,
                  height: rowHeight < 90 ? 90 : rowHeight,
                  alignment: pw.Alignment.center,
                  decoration: border,
                  child: pw.Text(dateEntry.key),
                ),

                /// LABS
                ...labOrder.map((lab) {

                  final todays = (dateEntry.value[lab] ?? [])
                      .cast<Map<String, dynamic>>();

                  Map<int, List<Map<String, dynamic>>> hourMap = {
                    for (var h in hourOrder) h: []
                  };

                  for (var e in todays) {
                    final hrs = (e["hours"] as List).cast<int>();
                    for (var h in hrs) {
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

                    /// compare by content safely
                    if (_same(entries, currentEntries)) {
                      currentHours.add(h);
                    } else {
                      blocks.add({
                        "entries": List.from(currentEntries),
                        "hours": List.from(currentHours),
                      });

                      currentEntries = List.from(entries);
                      currentHours = [h];
                    }
                  }

                  if (currentHours.isNotEmpty) {
                    blocks.add({
                      "entries": List.from(currentEntries),
                      "hours": List.from(currentHours),
                    });
                  }

                  /// MERGE FREE
                  List<Map<String, dynamic>> merged = [];

                  for (var b in blocks) {
                    final entries = b["entries"];

                    if (merged.isEmpty) {
                      merged.add(b);
                      continue;
                    }

                    final last = merged.last;

                    if (entries.isEmpty && last["entries"].isEmpty) {
                      (last["hours"] as List).addAll(b["hours"]);
                    } else {
                      merged.add(b);
                    }
                  }

                  blocks = merged;

                  List<pw.Widget> cells = [];

                  for (var b in blocks) {
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

                    String text;

                    if (isFree) {
                      text = "FREE\nHrs: ${formatBlock(hours)}";
                    } else {
                      text = entries.map((e) =>
                        "${e['class_name']}\n${e['subject_name']}"
                      ).join("\n\n") +
                      "\nHrs: ${formatBlock(hours)}";
                    }

                    cells.add(
                      pw.Container(
                        padding: const pw.EdgeInsets.all(3),
                        margin: const pw.EdgeInsets.only(bottom: 3),
                        color: color,
                        child: pw.Text(text, textAlign: pw.TextAlign.center),
                      ),
                    );
                  }

                  return pw.Container(
                    width: labColWidth,
                    height: rowHeight < 90 ? 90 : rowHeight,
                    padding: const pw.EdgeInsets.all(3),
                    decoration: border,
                    child: pw.Column(children: cells),
                  );

                }),
              ]);
            }),
          ],
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/lab_usage_matrix.pdf");

      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

    } catch (e) {
      print("PDF ERROR: $e");
    }
  }

  /// SAFE compare (order independent)
  static bool _same(List a, List b) {
    if (a.length != b.length) return false;

    List<String> ak = a.map((e) =>
      "${e['class_name']}_${e['subject_name']}_${e['external']}"
    ).toList()..sort();

    List<String> bk = b.map((e) =>
      "${e['class_name']}_${e['subject_name']}_${e['external']}"
    ).toList()..sort();

    for (int i = 0; i < ak.length; i++) {
      if (ak[i] != bk[i]) return false;
    }
    return true;
  }
}

