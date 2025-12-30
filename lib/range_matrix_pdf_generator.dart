import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'lab_controller.dart';

class RangeMatrixPdfGenerator {

  /// LABS TO SHOW
  static final List<String> labOrder = [
    'L1','L2','L3','L4','L5','L6','L7','L8','L9',
    'PG LAB'
  ];

  static final Map<String,String> displayName = {
    "PG LAB":"PG"
  };

  /// FORMAT HOUR RANGE
  static String formatHourRange(List<int> hours) {
    if (hours.isEmpty) return "";
    hours.sort();
    if (hours.length == 1) return hours.first.toString();
    return "${hours.first} To ${hours.last}";
  }

  /// FILTER LOGIC
  static bool matchFilter(dynamic value, String filter) {

    final ext = (value ?? "")
        .toString()
        .toLowerCase()
        .trim();

    final isExternal =
        ext.contains("yes") || ext.contains("external");

    if (filter == "external") return isExternal;
    if (filter == "internal") return !isExternal;

    return true; // both
  }

  static Future<void> generate({
    required DateTime startDate,
    required DateTime endDate,
    required LabController labController,
    required String filter,   /// 👈 NEW
  }) async {

    final pdf = pw.Document();
    final df = DateFormat('dd-MM-yyyy');

    /// -------- DATE LIST --------
    List<DateTime> dates = [];
    DateTime d = startDate;
    while(!d.isAfter(endDate)) {
      dates.add(d);
      d = d.add(const Duration(days: 1));
    }

    /// -------- MATRIX STRUCTURE --------
    final Map<String, Map<String, List<Map<String,dynamic>>>> matrix = {};

    for (final date in dates) {

      final dateStr = df.format(date);
      matrix[dateStr] = {};

      /// fetch daily data
      await labController.fetchLabAllotmentsForDate(date);

      for (final lab in labOrder) {

        final allotments =
          (labController.labAllotments[lab] ?? [])
            .cast<Map<String,dynamic>>();

        /// group by class+subject+external
        final grouped = <String, Map<String,dynamic>>{};

        for (var e in allotments) {

          /// APPLY FILTER HERE
          if (!matchFilter(e["external"], filter)) continue;

          final key =
            "${e['class_name']}_${e['subject_name']}_${e['external']}";

          final hour =
            int.tryParse(
              e["hours"]?.toString()
              ?? e["hours_allotted"]?.toString()
              ?? "0"
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

    /// -------- STYLES --------
    final blue  = PdfColor.fromInt(0xFFADD8E6);   // internal
    final green = PdfColor.fromInt(0xFF90EE90);   // external
    final border = pw.BoxDecoration(border: pw.Border.all());

    /// -------- WIDTHS --------
    final pageWidth = PdfPageFormat.a4.landscape.width - 20;
    final dateColWidth = 90.0;
    final labColWidth = (pageWidth - dateColWidth) / labOrder.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(10),
        build: (_) => [

          pw.Text(
            "LAB ALLOTMENT (${filter.toUpperCase()})",
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            "From: ${df.format(startDate)}   To: ${df.format(endDate)}",
            style: const pw.TextStyle(fontSize: 13),
          ),

          pw.SizedBox(height: 10),

          /// HEADER
          pw.Row(children: [

            pw.Container(
              width: dateColWidth,
              height: 30,
              alignment: pw.Alignment.center,
              decoration: border,
              child: pw.Text(
                "DATE",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),

            ...labOrder.map((lab)=>
              pw.Container(
                width: labColWidth,
                height: 30,
                alignment: pw.Alignment.center,
                decoration: border,
                child: pw.Text(
                  displayName[lab] ?? lab,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              )
            ),
          ]),

          pw.SizedBox(height: 3),

          /// ROWS
          ...matrix.entries.map((dateEntry){

            return pw.Row(children: [

              pw.Container(
                width: dateColWidth,
                height: 85,
                alignment: pw.Alignment.center,
                decoration: border,
                child: pw.Text(dateEntry.key),
              ),

              ...labOrder.map((lab){

                final todays = dateEntry.value[lab] ?? [];

                if (todays.isEmpty) {
                  return pw.Container(
                    width: labColWidth,
                    height: 85,
                    alignment: pw.Alignment.center,
                    decoration: border,
                    child: pw.Text(""),
                  );
                }

                return pw.Container(
                  width: labColWidth,
                  height: 85,
                  padding: pw.EdgeInsets.all(3),
                  decoration: border,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: todays.map((e){

                      final hours =
                        (e["hours"] as List<int>);

                      final hrStr = formatHourRange(hours);

                      final external =
                        (e["external"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains("yes") ||
                        (e["external"] ?? "")
                          .toString()
                          .toLowerCase()
                          .contains("external");

                      final color = external ? green : blue;

                      return pw.Container(
                        width: double.infinity,
                        padding: pw.EdgeInsets.all(3),
                        margin: pw.EdgeInsets.only(bottom: 3),
                        color: color,
                        child: pw.Text(
                          "${e['class_name'] ?? ''}\n"
                          "${e['subject_name'] ?? ''}\n"
                          "Hrs: $hrStr",
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 8),
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
    final file = File("${dir.path}/lab_usage_matrix.pdf");

    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
