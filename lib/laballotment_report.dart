import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import 'lab_controller.dart';

class LabAllotmentsReport extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const LabAllotmentsReport({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  _LabAllotmentsReportState createState() => _LabAllotmentsReportState();
}

class _LabAllotmentsReportState extends State<LabAllotmentsReport> {
  final LabController labController = Get.find();

  final List<String> labOrder = [
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

  Map<String, Map<String, List<Map<String, dynamic>>>> reportData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // -------------------------------------------------------------------
  // 🔵 MERGE CONTINUOUS HOURS FOR SAME SUBJECT & CLASS
  // -------------------------------------------------------------------
  List<Map<String, dynamic>> mergeHours(List<Map<String, dynamic>> list) {
    if (list.isEmpty) return [];

    list.sort((a, b) => int.parse(a['hours'].toString())
        .compareTo(int.parse(b['hours'].toString())));

    List<Map<String, dynamic>> merged = [];

    String currentSubject = list.first['subject_name'];
    String currentClass = list.first['class_name'];
    int startHour = int.parse(list.first['hours']);
    int endHour = startHour;

    for (int i = 1; i < list.length; i++) {
      var item = list[i];
      int hour = int.parse(item['hours']);
      String subj = item['subject_name'];
      String cls = item['class_name'];

      // Continue block
      if (subj == currentSubject &&
          cls == currentClass &&
          hour == endHour + 1) {
        endHour = hour;
      } else {
        merged.add({
          'subject_name': currentSubject,
          'class_name': currentClass,
          'hours': startHour == endHour ? "$startHour" : "$startHour–$endHour",
        });

        // Start new block
        currentSubject = subj;
        currentClass = cls;
        startHour = hour;
        endHour = hour;
      }
    }

    // Final block
    merged.add({
      'subject_name': currentSubject,
      'class_name': currentClass,
      'hours': startHour == endHour ? "$startHour" : "$startHour–$endHour",
    });

    return merged;
  }

  // -------------------------------------------------------------------
  // 🔵 FETCH RANGE & MERGE HOURS
  // -------------------------------------------------------------------
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
      fetchExternalReport(DateTime start, DateTime end) async {
    Map<String, Map<String, List<Map<String, dynamic>>>> result = {};

    DateTime date = start;

    while (date.isBefore(end.add(const Duration(days: 1)))) {
      await labController.fetchLabAllotmentsForDate(date);

      for (var lab in labOrder) {
        final allotments = labController.labAllotments[lab] ?? [];

        final external = allotments.where((e) {
          final ext = (e['external'] ?? "").toString().toLowerCase();
          return ext == "external" || ext == "yes";
        }).toList();

        if (external.isNotEmpty) {
          result.putIfAbsent(lab, () => {});
          result[lab]![DateFormat('dd-MM-yyyy').format(date)] =
              mergeHours(external);
        }
      }

      date = date.add(const Duration(days: 1));
    }

    return result;
  }

  Future<void> _loadData() async {
    reportData = await fetchExternalReport(widget.startDate, widget.endDate);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('External Allotments Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfReport,
          )
        ],
      ),
      body: reportData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: reportData.entries.map((labEntry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Lab: ${labEntry.key}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ...labEntry.value.entries.map((dateEntry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "  ${dateEntry.key}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue,
                            ),
                          ),
                          ...dateEntry.value.map((e) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 20, top: 4),
                              child: Text(
                                "${e['class_name']}  "
                                "${e['subject_name']} "
                                "Hours: ${e['hours']}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),
                    const Divider(height: 30),
                  ],
                );
              }).toList(),
            ),
    );
  }

  // -------------------------------------------------------------------
  // 🔵 PDF GENERATION
  // -------------------------------------------------------------------
  Future<void> _generatePdfReport() async {
    if (reportData.isEmpty) {
      Get.snackbar("Error", "No external allotments available");
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(16),
        build: (_) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "External Lab Allotment",
                style:
                    pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                "From: ${DateFormat('dd-MM-yyyy').format(widget.startDate)}     "
                "To: ${DateFormat('dd-MM-yyyy').format(widget.endDate)}",
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              ...reportData.entries.map((labEntry) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      "Lab: ${labEntry.key}",
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 6),
                    ...labEntry.value.entries.map((dateEntry) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            dateEntry.key,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                              color: PdfColor.fromHex("#0000FF"),
                            ),
                          ),
                          ...dateEntry.value.map((e) {
                            return pw.Text(
                              "${e['class_name']}  "
                              "${e['subject_name']}  "
                              "Hours: ${e['hours'].toString().replaceAll('-', '–')}",
                              style: pw.TextStyle(
                                color: PdfColor.fromHex("#FF0000"),
                              ),
                            );
                          }),
                          pw.SizedBox(height: 10),
                        ],
                      );
                    }),
                    pw.SizedBox(height: 20),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/external_lab_report.pdf");

    await file.writeAsBytes(await pdf.save());
    await OpenFile.open(file.path);
  }
}
