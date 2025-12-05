import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'lab_controller.dart';

class DailyGridPdfGenerator {
  // BACKEND LAB NAMES (MUST MATCH API RESPONSE)
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
    'MICRO PROCESSOR LAB',
    'PG LAB'
  ];

  // DISPLAY NAMES FOR PDF (SHORT NAMES)
  static final Map<String, String> displayName = {
    "MICRO PROCESSOR LAB": "MP",
    "PG LAB": "PG",
  };

  // HOUR COLUMNS
  static final List<String> hours = [
    'H1', 'H2', 'H3', 'H4', 'LB', 'H5', 'H6', 'H7'
  ];

  // MAP UI hours → backend numbers
  static final Map<String, String> hourNum = {
    "H1": "1",
    "H2": "2",
    "H3": "3",
    "H4": "4",
    "LB": "8",
    "H5": "5",
    "H6": "6",
    "H7": "7",
  };

  static Future<void> generate({
    required DateTime date,
    required LabController labController,
  }) async {
    final pdf = pw.Document();
    final df = DateFormat("dd-MM-yyyy");
    final formattedDate = df.format(date);

    // BUILD TABLE EXACTLY LIKE UI
    Map<String, Map<String, Map<String, dynamic>>> table = {};

    for (var lab in labOrder) {
      table[lab] = {};

      final entries =
          (labController.labAllotments[lab] ?? []).cast<Map<String, dynamic>>();

      for (var entry in entries) {
        // API returns only ONE hour per entry → "hours": "3"
        final hr = entry["hours"]?.toString().trim();

        if (hr != null && hr.isNotEmpty) {
          table[lab]![hr] = entry;
        }
      }
    }

    final freeColor = PdfColor.fromInt(0xFFD3D3D3); // grey
    final allotColor = PdfColor.fromInt(0xFF90EE90); // green

    final titleStyle =
        pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold);
    final headerStyle =
        pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final cellStyle = pw.TextStyle(fontSize: 9);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(10),
        build: (ctx) {
          return pw.Column(
            children: [
              // 🔥 MERGED HEADER
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                alignment: pw.Alignment.center,
                child: pw.Text("DAILY LAB ALLOTMENT", style: titleStyle),
              ),

              pw.SizedBox(height: 4),
              pw.Text("Date: $formattedDate", style: headerStyle),
              pw.SizedBox(height: 10),

              // 🔥 GRID TABLE
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  // HEADER ROW
                  pw.TableRow(
                    children: [
                      pw.Container(
                        height: 32,
                        alignment: pw.Alignment.center,
                        child: pw.Text("LAB", style: headerStyle),
                      ),
                      ...hours.map((h) => pw.Container(
                            height: 32,
                            alignment: pw.Alignment.center,
                            child: pw.Text(h, style: headerStyle),
                          )),
                    ],
                  ),

                  // DATA ROWS
                  ...labOrder.map((lab) {
                    return pw.TableRow(
                      children: [
                        // LAB NAME COLUMN
                        pw.Container(
                          height: 32,
                          alignment: pw.Alignment.center,
                          child: pw.Text(
                            displayName[lab] ?? lab, // SHORT DISPLAY NAME
                            style: headerStyle,
                          ),
                        ),

                        // HOUR CELLS
                        ...hours.map((hr) {
                          String hrKey = hourNum[hr]!;
                          final allot = table[lab]![hrKey];

                          if (allot == null) {
                            // FREE
                            return pw.Container(
                              height: 32,
                              alignment: pw.Alignment.center,
                              color: freeColor,
                              child: pw.Text(""),
                            );
                          }

                          // ALLOTTED
                          final subject = allot["subject_name"] ?? "";
                          final cls = allot["class_name"] ?? "";

                          return pw.Container(
                            height: 32,
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(3),
                            color: allotColor,
                            child: pw.Text(
                              "$subject\n$cls",
                              style: cellStyle,
                              textAlign: pw.TextAlign.center,
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 8),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Generated by FISAT Timetable",
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColor.fromInt(0xFF777777)),
                ),
              ),
            ],
          );
        },
      ),
    );

    // SAVE FILE
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/lab_allotment_${formattedDate}.pdf");

    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
