import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'lab_controller.dart';

class LabAllotmentsReport extends StatefulWidget {
  const LabAllotmentsReport({super.key});

  @override
  _LabAllotmentsReportState createState() => _LabAllotmentsReportState();
}

class _LabAllotmentsReportState extends State<LabAllotmentsReport> {
  final LabController labController = Get.find();

  // Define the custom order for labs
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

  bool showExternalOnly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Allotments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _displayReportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generatePdfReport(),
          ),
        ],
      ),
      body: Obx(() {
        final sortedLabAllotments =
            Map<String, List<Map<String, String>>>.fromEntries(labOrder
                .where((lab) => labController.labAllotmentsR.containsKey(lab))
                .map((lab) {
          var allotments = labController.labAllotmentsR[lab]!.map((allotment) {
            return {
              'subject_name': allotment['subject_name']?.toString() ?? '',
              'class_name': allotment['class_name']?.toString() ?? '',
              'hours': allotment['hours']?.toString() ?? '',
              'external': allotment['external']?.toString() ?? '',
            };
          }).toList();

          allotments.sort((a, b) {
            final hoursA = int.tryParse(a['hours'] ?? '0') ?? 0;
            final hoursB = int.tryParse(b['hours'] ?? '0') ?? 0;
            return hoursA.compareTo(hoursB);
          });

          return MapEntry(lab, allotments);
        }));

        if (sortedLabAllotments.isNotEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: sortedLabAllotments.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lab: ${entry.key}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  ...entry.value.map((allotment) {
                    return Text(
                        'Subject: ${allotment['subject_name']}, Class: ${allotment['class_name']}, Hours: ${allotment['hours']}');
                  }),
                  const SizedBox(height: 10),
                ],
              );
            }).toList(),
          );
        } else {
          return const Center(
              child: Text('No allotments found for the selected date.'));
        }
      }),
    );
  }

  void _displayReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final reportContent = labOrder
                .map((lab) {
                  final allotments = labController.labAllotmentsR[lab] ?? [];
                  final filteredAllotments = allotments.where((allotment) {
                    return !showExternalOnly ||
                        allotment['external'] == 'external';
                  }).map((allotment) {
                    return 'Subject: ${allotment['subject_name']}, Class: ${allotment['class_name']}, Hours: ${allotment['hours']}';
                  }).join('\n');

                  return filteredAllotments.isNotEmpty
                      ? 'Lab: $lab\n$filteredAllotments'
                      : '';
                })
                .where((entry) => entry.isNotEmpty)
                .join('\n\n');

            return AlertDialog(
              title: const Text('Lab Allotments Report'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filter options:'),
                    Row(
                      children: [
                        Checkbox(
                          value: showExternalOnly,
                          onChanged: (bool? value) {
                            setState(() {
                              showExternalOnly = value ?? false;
                            });
                          },
                        ),
                        const Text('Show External Only'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(reportContent),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Future<void> _generatePdfReport() async {
  //   // Request storage permission
  //   if (await Permission.storage.request().isGranted) {
  //     // Create a PDF document
  //     final pdf = pw.Document();

  //     // Add a page to the PDF document
  //     pdf.addPage(
  //       pw.Page(
  //         build: (pw.Context context) {
  //           return pw.Column(
  //             crossAxisAlignment: pw.CrossAxisAlignment.start,
  //             children: labOrder.map((lab) {
  //               final allotments = labController.labAllotmentsR[lab] ?? [];
  //               final filteredAllotments = allotments.where((allotment) {
  //                 return !showExternalOnly ||
  //                     allotment['external'] == 'external';
  //               }).map((allotment) {
  //                 return pw.Text(
  //                   'Subject: ${allotment['subject_name']}, Class: ${allotment['class_name']}, Hours: ${allotment['hours']}',
  //                   style: pw.TextStyle(
  //                     color: allotment['external'] == 'external'
  //                         ? PdfColor.fromHex("#FF0000")
  //                         : PdfColor.fromHex(
  //                             "#000000"), // Red color in hexadecimal
  //                   ),
  //                 );
  //               }).toList();

  //               return filteredAllotments.isNotEmpty
  //                   ? pw.Column(
  //                       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                       children: [
  //                         pw.Text('Lab: $lab',
  //                             style:
  //                                 pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  //                         ...filteredAllotments,
  //                         pw.SizedBox(height: 10),
  //                       ],
  //                     )
  //                   : pw.Container();
  //             }).toList(),
  //           );
  //         },
  //       ),
  //     );

  //     // Get the directory to save the PDF
  //     final outputDir = await getExternalStorageDirectory();
  //     final outputFile = File("${outputDir!.path}/lab_allotments_report.pdf");

  //     // Save the PDF to the file
  //     await outputFile.writeAsBytes(await pdf.save());

  //     // Open the PDF file
  //     await OpenFile.open(outputFile.path);
  //   } else {
  //     // Handle the case when permission is denied
  //     Get.snackbar("Permission Denied",
  //         "Storage permission is required to save the PDF.");
  //   }
  // }

  Future<void> _generatePdfReport() async {
    // Create a PDF document (no need for permissions)
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: labOrder.map((lab) {
              final allotments = labController.labAllotmentsR[lab] ?? [];
              final filteredAllotments = allotments.where((allotment) {
                return !showExternalOnly || allotment['external'] == 'external';
              }).map((allotment) {
                return pw.Text(
                  'Subject: ${allotment['subject_name']}, Class: ${allotment['class_name']}, Hours: ${allotment['hours']}',
                  style: pw.TextStyle(
                    color: allotment['external'] == 'external'
                        ? PdfColor.fromHex("#FF0000")
                        : PdfColor.fromHex("#000000"),
                  ),
                );
              }).toList();

              return filteredAllotments.isNotEmpty
                  ? pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Lab: $lab',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ...filteredAllotments,
                        pw.SizedBox(height: 10),
                      ],
                    )
                  : pw.Container();
            }).toList(),
          );
        },
      ),
    );

    // Save inside app documents folder → NO PERMISSION NEEDED
    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/lab_allotments_report.pdf");

    await file.writeAsBytes(await pdf.save());

    // Open PDF
    await OpenFile.open(file.path);
  }
}
