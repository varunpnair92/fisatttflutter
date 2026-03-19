import 'package:fisat_timetable/cummilative_data_display.dart';
import 'package:fisat_timetable/daily_report_pdf.dart';
import 'package:fisat_timetable/free_slot_pdf.dart';
import 'package:fisat_timetable/range_matrix_pdf_generator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'lab_controller.dart';
import 'laballotment_report.dart';

class SaveAllotmentPage extends StatelessWidget {
  final LabController labController = Get.put(LabController());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final List<String> labNames = [
    'L1',
    'L2',
    'L3',
    'L4',
    'L5',
    'L6',
    'L7',
    'L8',
    'L9',
    'MP',
    'PG'
  ];

  final List<String> hoursList = ['1', '2', '3', '4', 'LB', '5', '6', '7'];

  SaveAllotmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Allotment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Lab Name'),
                items: labNames
                    .map(
                        (lab) => DropdownMenuItem(value: lab, child: Text(lab)))
                    .toList(),
                onChanged: (value) {
                  if (value == 'PG') {
                    labController.formData['lab_name'] = 'PG LAB';
                  } else if (value == 'MP') {
                    labController.formData['lab_name'] = 'MICRO PROCESSOR LAB';
                  } else {
                    labController.formData['lab_name'] = value ?? '';
                  }
                },
                validator: (value) {
                  if (labController.selectedLabs.isNotEmpty) {
                    return null; // multi-lab selected → no need single lab
                  }
                  if (value == null) return 'Please select a lab';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // ================= MULTIPLE LAB SELECT (NEW)

              Obx(() => InkWell(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Select Labs"),
                            content: SingleChildScrollView(
                              child: Column(
                                children: labNames.map((lab) {
                                  return Obx(() => CheckboxListTile(
                                        title: Text(lab),
                                        value: labController.selectedLabs
                                            .contains(lab),
                                        onChanged: (bool? selected) {
                                          if (selected == true) {
                                            labController.selectedLabs.add(lab);
                                          } else {
                                            labController.selectedLabs
                                                .remove(lab);
                                          }
                                        },
                                      ));
                                }).toList(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text("Done"),
                              )
                            ],
                          );
                        },
                      );
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Multi Lab Selection",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        labController.selectedLabs.isEmpty
                            ? "Tap to select labs"
                            : labController.selectedLabs.join(', '),
                      ),
                    ),
                  )),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'From Hour'),
                      items: hoursList
                          .map((hour) =>
                              DropdownMenuItem(value: hour, child: Text(hour)))
                          .toList(),
                      onChanged: (value) =>
                          labController.formData['from_hour'] = value ?? '',
                      validator: (value) =>
                          value == null ? 'Select from hour' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'To Hour'),
                      items: hoursList
                          .map((hour) =>
                              DropdownMenuItem(value: hour, child: Text(hour)))
                          .toList(),
                      onChanged: (value) =>
                          labController.formData['to_hour'] = value ?? '',
                      validator: (value) =>
                          value == null ? 'Select to hour' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Subject Name'),
                onChanged: (value) =>
                    labController.formData['subject_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter subject name' : null,
              ),

              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Class Name'),
                onChanged: (value) =>
                    labController.formData['class_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter class name' : null,
              ),

              const SizedBox(height: 16),

              _buildDateField(
                'Start Date',
                _startDateController,
                'start_date',
                context,
              ),

              const SizedBox(height: 16),

              _buildDateField(
                'End Date',
                _endDateController,
                'end_date',
                context,
              ),

              const SizedBox(height: 20),

              const Text('Allot:'),

              Obx(() => ListTile(
                    title: const Text('Continue'),
                    leading: Radio<String>(
                      value: 'continue',
                      groupValue: labController.formData['allot'],
                      onChanged: (value) =>
                          labController.formData['allot'] = value!,
                    ),
                  )),

              Obx(() => ListTile(
                    title: const Text('Repeat'),
                    leading: Radio<String>(
                      value: 'repeat',
                      groupValue: labController.formData['allot'],
                      onChanged: (value) =>
                          labController.formData['allot'] = value!,
                    ),
                  )),

              const SizedBox(height: 20),

              // -------------------------------------------------------
              //     FILTER TOGGLE FOR PDF
              // -------------------------------------------------------
              const Text("PDF Filter:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Obx(() => Row(
                    children: [
                      ChoiceChip(
                        label: const Text("Internal"),
                        selected: labController.pdfFilter.value == "internal",
                        onSelected: (_) =>
                            labController.pdfFilter.value = "internal",
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("External"),
                        selected: labController.pdfFilter.value == "external",
                        onSelected: (_) =>
                            labController.pdfFilter.value = "external",
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text("Both"),
                        selected: labController.pdfFilter.value == "both",
                        onSelected: (_) =>
                            labController.pdfFilter.value = "both",
                      ),
                    ],
                  )),
              const SizedBox(height: 25),

              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (!labController.formData.containsKey('allot')) {
                        Get.snackbar(
                            "Error", "Please select Continue or Repeat");
                        return;
                      }

                      final fromHour = labController.formData['from_hour'];
                      final toHour = labController.formData['to_hour'];

                      if (fromHour != null && toHour != null) {
                        final from = hoursList.indexOf(fromHour);
                        final to = hoursList.indexOf(toHour);

                        if (from <= to) {
                          final selectedHours = hoursList
                              .sublist(from, to + 1)
                              .map((h) => h == "LB" ? "8" : h)
                              .toList();

                          labController.formData['hours_allotted'] =
                              selectedHours.join(',');

                          labController.formData.remove('from_hour');
                          labController.formData.remove('to_hour');
                          // ================= NEW: Attach multi labs if selected
                          // ================= NEW: Attach multi labs if selected
                          if (labController.selectedLabs.isNotEmpty) {
                            labController.formData['lab_names'] =
                                labController.selectedLabs.toList();
                          }
                          // ✅ SEND AS LIST

                          labController.saveData(
                            formKey: _formKey,
                            startDateController: _startDateController,
                            endDateController: _endDateController,
                          );
                        } else {
                          Get.snackbar(
                              "Invalid", "From hour must be ≤ To hour");
                        }
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_startDateController.text.isEmpty ||
                        _endDateController.text.isEmpty) {
                      Get.snackbar("Error", "Select Start & End Dates");
                      return;
                    }

                    final start = DateFormat('dd-MM-yyyy')
                        .parse(_startDateController.text);

                    final end =
                        DateFormat('dd-MM-yyyy').parse(_endDateController.text);

                    await RangeMatrixFreeSlotsPdfGenerator.generate(
                      startDate: start,
                      endDate: end,
                      labController: labController,
                    );
                  },
                  child: const Text("Free Slots"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_startDateController.text.isEmpty ||
                        _endDateController.text.isEmpty) {
                      Get.snackbar("Error", "Select both start & end dates");
                      return;
                    }

                    final start = DateFormat('dd-MM-yyyy')
                        .parse(_startDateController.text);
                    final end =
                        DateFormat('dd-MM-yyyy').parse(_endDateController.text);

                    Get.to(() => CumulativePage(start: start, end: end));
                  },
                  child: const Text("External Summary"),
                ),
              ]),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_startDateController.text.isNotEmpty &&
                          _endDateController.text.isNotEmpty) {
                        final start = DateFormat('dd-MM-yyyy')
                            .parse(_startDateController.text);
                        final end = DateFormat('dd-MM-yyyy')
                            .parse(_endDateController.text);

                        await labController.fetchLabAllotmentsForRange(
                            start, end);

                        Get.to(
                          LabAllotmentsReport(
                            startDate: start,
                            endDate: end,
                          ),
                        );
                      } else {
                        Get.snackbar("Error", "Select both start & end dates");
                      }
                    },
                    child: const Text('Generate Report'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_startDateController.text.isEmpty ||
                          _endDateController.text.isEmpty) {
                        Get.snackbar("Error", "Select Start & End Dates");
                        return;
                      }

                      final start = DateFormat('dd-MM-yyyy')
                          .parse(_startDateController.text);
                      final end = DateFormat('dd-MM-yyyy')
                          .parse(_endDateController.text);

                      // 🔥 ADD HERE
                      labController.labAllotmentsR.clear();

                      await labController.fetchLabAllotmentsForRange(
                          start, end);

                      await RangeMatrixPdfGenerator.generate(
                        startDate: start,
                        endDate: end,
                        labController: labController,
                        filter: labController.pdfFilter.value,
                       // useRangeCache: true,
                      );
                    },
                    child: const Text("Date PDF"),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_startDateController.text.isEmpty) {
                        Get.snackbar("Error", "Select Start Date first.");
                        return;
                      }

                      final DateTime date = DateFormat('dd-MM-yyyy')
                          .parse(_startDateController.text);

                      await labController.fetchLabAllotmentsForDate(date);

                      await DailyGridPdfGenerator.generate(
                        date: date,
                        labController: labController,
                        filter: labController.pdfFilter.value, // PASS FILTER
                      );
                    },
                    child: const Text("Generate Daily PDF"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    String field,
    BuildContext context,
  ) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );

        if (selectedDate != null) {
          final formatted = DateFormat('dd-MM-yyyy').format(selectedDate);
          controller.text = formatted;
          labController.formData[field] = formatted;
        }
      },
      validator: (value) => value!.isEmpty ? 'Select $label' : null,
    );
  }
}
