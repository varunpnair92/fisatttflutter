import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'lab_controller.dart';

class RangeMatrixFreeSlotsPdfGenerator {
  /// SAME LAB ORDER AS EXISTING PDF
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

  static Future<void> generate({
    required DateTime startDate,
    required DateTime endDate,
    required LabController labController,
  }) async {
    final pdf = pw.Document();
    final df = DateFormat('dd-MM-yyyy');

    /// -------- DATE LIST --------
    List<DateTime> dates = [];
    DateTime d = startDate;

    while (!d.isAfter(endDate)) {
      dates.add(d);
      d = d.add(const Duration(days: 1));
    }

    /// -------- MATRIX FOR FREE SLOTS --------
    final Map<String, Map<String, String>> matrix = {};

    /// CALL EXISTING API FOR RANGE FREE SLOTS
    final apiResponse =
        await labController.fetchFreeSlotsRange(startDate, endDate);

    /// API RETURNS { start_date, end_date, data: [...] }
    final List<dynamic> freeData = apiResponse["data"] ?? [];

    /// Convert API response into matrix format
    for (var day in freeData) {
      if (day == null) continue;

      final date = (day["date"] ?? "").toString().trim();

      if (date.isEmpty) continue;

      matrix[date] = {};

      /// initialize all labs empty
      for (var lab in labOrder) {
        matrix[date]![lab] = "";
      }

      final slots = day["free_slots"] ?? [];

      for (var slot in slots) {
        final lab = (slot["lab_name"] ?? "").toString().trim();
        final hours = (slot["hours_free"] ?? "").toString();

        String normalizedLab = lab;

        /// Normalize MP name if required
        if (lab == "MP") {
          normalizedLab = "MICRO PROCESSOR LAB";
        }

        if (labOrder.contains(normalizedLab)) {
          matrix[date]![normalizedLab] = hours;
        }
      }
    }

    /// -------- STYLES --------
    const red = PdfColor.fromInt(0xFFFFCCCC);
    final border = pw.BoxDecoration(border: pw.Border.all());

    /// -------- WIDTHS --------
    final pageWidth = PdfPageFormat.a4.landscape.width - 20;
    const dateColWidth = 90.0;
    final labColWidth = (pageWidth - dateColWidth) / labOrder.length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(10),
        build: (_) => [
          pw.Text(
            "FREE SLOTS REPORT",
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            "From: ${df.format(startDate)}   To: ${df.format(endDate)}",
            style: const pw.TextStyle(fontSize: 13),
          ),

          pw.SizedBox(height: 10),

          /// HEADER ROW
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
            ...labOrder.map((lab) => pw.Container(
                  width: labColWidth,
                  height: 30,
                  alignment: pw.Alignment.center,
                  decoration: border,
                  child: pw.Text(
                    displayName[lab] ?? lab,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                )),
          ]),

          pw.SizedBox(height: 3),

          /// DATA ROWS
          ...matrix.entries.map((entry) {
            final date = entry.key;

            return pw.Row(children: [
              pw.Container(
                width: dateColWidth,
                height: 70,
                alignment: pw.Alignment.center,
                decoration: border,
                child: pw.Text(date),
              ),
              ...labOrder.map((lab) {
                final hours = entry.value[lab] ?? "";

                return pw.Container(
                  width: labColWidth,
                  height: 70,
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: border,
                  child: hours.isEmpty
                      ? pw.Text("")
                      : pw.Container(
                          padding: const pw.EdgeInsets.all(5),
                          color: red,
                          child: pw.Text(
                            "Free: $hours",
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                );
              }),
            ]);
          }),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/free_slots_report.pdf");

    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
