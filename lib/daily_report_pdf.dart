import 'dart:io';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'lab_controller.dart';

class DailyGridPdfGenerator {
  static final List<String> labOrder = [
    "L1",
    "L2",
    "L3",
    "L4",
    "L5",
    "L6",
    "L7",
    "L8",
    "L9",
    "MICRO PROCESSOR LAB",
    "PG LAB",
  ];

  static final Map<String, String> displayName = {
    "MICRO PROCESSOR LAB": "MP",
    "PG LAB": "PG"
  };

  static final List<String> uiHours = [
    "H1",
    "H2",
    "H3",
    "H4",
    "LB",
    "H5",
    "H6",
    "H7"
  ];

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
    required String filter, // NEW FILTER PARAMETER
  }) async {
    final pdf = pw.Document();
    final df = DateFormat("dd-MM-yyyy");

    final formattedDate = df.format(date);
    final labMap = labController.labAllotments;

    // Build table map
    Map<String, Map<String, Map<String, dynamic>>> table = {};

    for (var lab in labOrder) {
      table[lab] = {};

      var entries = (labMap[lab] ?? []).cast<Map<String, dynamic>>();

      // APPLY FILTER -------------------------
      entries = entries.where((e) {
        final ext = (e["external"] ?? "").toString().toLowerCase();
        if (filter == "internal") return ext != "external" && ext != "yes";
        if (filter == "external") return ext == "external" || ext == "yes";
        return true; // both
      }).toList();
      // --------------------------------------

      for (var e in entries) {
        final hr = e["hours"]?.toString();

        final subj = (e["subject_name"] ?? "").toString().toLowerCase().trim();
        final cls = (e["class_name"] ?? "").toString().toLowerCase().trim();

        // 🚫 IGNORE FREE ENTRIES
        if (subj == "free" || cls == "free") continue;

        if (hr != null && hr.isNotEmpty) {
          table[lab]![hr] = e;
        }
      }
    }

    final pageWidth = PdfPageFormat.a4.landscape.width - 20;
    final labColWidth = 55.0;
    final remaining = pageWidth - labColWidth;

    final hourWidth = (remaining / uiHours.length).floorToDouble();
    final lastHourWidth = remaining - hourWidth * (uiHours.length - 1);

    final freeColor = PdfColor.fromInt(0xFFD3D3D3);
    final greenColor = PdfColor.fromInt(0xFF90EE90);
    final redColor = PdfColor.fromInt(0xFFFFA0A0);

    final headerStyle =
        pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final cellStyle = pw.TextStyle(fontSize: 9);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.all(10),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  "LAB ALLOTMENT ($formattedDate)",
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),

              pw.SizedBox(height: 5),
              pw.Text("Date: $formattedDate", style: headerStyle),

              pw.SizedBox(height: 8),

              // HEADER
              pw.Row(
                children: [
                  pw.Container(
                    width: labColWidth,
                    height: 32,
                    alignment: pw.Alignment.center,
                    decoration: pw.BoxDecoration(border: pw.Border.all()),
                    child: pw.Text("LAB", style: headerStyle),
                  ),
                  ...List.generate(uiHours.length, (i) {
                    final w =
                        (i == uiHours.length - 1) ? lastHourWidth : hourWidth;
                    return pw.Container(
                      width: w,
                      height: 32,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Text(uiHours[i], style: headerStyle),
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 2),

              ...labOrder.map((lab) {
                return _buildLabRow(
                  lab: lab,
                  table: table[lab]!,
                  labColWidth: labColWidth,
                  hourWidth: hourWidth,
                  lastHourWidth: lastHourWidth,
                  freeColor: freeColor,
                  greenColor: greenColor,
                  redColor: redColor,
                  headerStyle: headerStyle,
                  cellStyle: cellStyle,
                );
              }),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/daily_lab_${formattedDate}.pdf");
    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }

  static pw.Widget _buildLabRow({
    required String lab,
    required Map<String, dynamic> table,
    required double labColWidth,
    required double hourWidth,
    required double lastHourWidth,
    required PdfColor freeColor,
    required PdfColor greenColor,
    required PdfColor redColor,
    required pw.TextStyle headerStyle,
    required pw.TextStyle cellStyle,
  }) {
    List<String> hourOrder = ["1", "2", "3", "4", "8", "5", "6", "7"];
    List<pw.Widget> cells = [];

    cells.add(
      pw.Container(
        width: labColWidth,
        height: 34,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(border: pw.Border.all()),
        child: pw.Text(displayName[lab] ?? lab, style: headerStyle),
      ),
    );

    int i = 0;
    while (i < hourOrder.length) {
      final hr = hourOrder[i];
      final entry = table[hr];

      final baseWidth = (i == hourOrder.length - 1) ? lastHourWidth : hourWidth;

      if (entry == null) {
        cells.add(_freeCell(baseWidth, freeColor));
        i++;
        continue;
      }

      final subj = entry["subject_name"] ?? "";
      final cls = entry["class_name"] ?? "";
      final ext = entry["external"]?.toString()?.toLowerCase() ?? "no";

      final PdfColor color =
          (ext == "external" || ext == "yes") ? redColor : greenColor;

      int span = 1;
      int j = i + 1;

      while (j < hourOrder.length) {
        final next = table[hourOrder[j]];
        if (next == null) break;

        if (next["subject_name"] == subj &&
            next["class_name"] == cls &&
            next["external"].toString().toLowerCase() == ext) {
          span++;
          j++;
        } else
          break;
      }

      double mergedWidth = 0;
      for (int k = i; k < j; k++) {
        mergedWidth += (k == hourOrder.length - 1) ? lastHourWidth : hourWidth;
      }

      cells.add(
        pw.Container(
          width: mergedWidth,
          height: 34,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(border: pw.Border.all(), color: color),
          padding: pw.EdgeInsets.all(3),
          child: pw.Text(
            "$subj\n$cls",
            style: cellStyle,
            textAlign: pw.TextAlign.center,
          ),
        ),
      );

      i = j;
    }

    return pw.Row(children: cells);
  }

  static pw.Widget _freeCell(double width, PdfColor color) {
    return pw.Container(
      width: width,
      height: 34,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(border: pw.Border.all(), color: color),
      child: pw.Text(""),
    );
  }
}
