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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Save Allotment')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Lab Name'),
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
                validator: (value) =>
                    value == null ? 'Please select a lab' : null,
              ),

              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'From Hour'),
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
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'To Hour'),
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

              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(labelText: 'Subject Name'),
                onChanged: (value) =>
                    labController.formData['subject_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter subject name' : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                decoration: InputDecoration(labelText: 'Class Name'),
                onChanged: (value) =>
                    labController.formData['class_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter class name' : null,
              ),

              SizedBox(height: 16),

              _buildDateField(
                'Start Date',
                _startDateController,
                'start_date',
                context,
              ),

              SizedBox(height: 16),

              _buildDateField(
                'End Date',
                _endDateController,
                'end_date',
                context,
              ),

              SizedBox(height: 20),

              Text('Allot:'),

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

              SizedBox(height: 20),

              // -------------------------------------------------------
              //     FILTER TOGGLE FOR PDF
              // -------------------------------------------------------
              Text("PDF Filter:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Obx(() => Row(
                    children: [
                      ChoiceChip(
                        label: Text("Internal"),
                        selected: labController.pdfFilter.value == "internal",
                        onSelected: (_) =>
                            labController.pdfFilter.value = "internal",
                      ),
                      SizedBox(width: 10),
                      ChoiceChip(
                        label: Text("External"),
                        selected: labController.pdfFilter.value == "external",
                        onSelected: (_) =>
                            labController.pdfFilter.value = "external",
                      ),
                      SizedBox(width: 10),
                      ChoiceChip(
                        label: Text("Both"),
                        selected: labController.pdfFilter.value == "both",
                        onSelected: (_) =>
                            labController.pdfFilter.value = "both",
                      ),
                    ],
                  )),
              SizedBox(height: 25),

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
                  child: Text('Save'),
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
                  child: Text("Free Slots"),
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

              SizedBox(height: 20),

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
                    child: Text('Generate Report'),
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

                      await labController.fetchLabAllotmentsForRange(
                          start, end);

                      await RangeMatrixPdfGenerator.generate(
                        startDate: start,
                        endDate: end,
                        labController: labController,
                        filter: labController.pdfFilter.value,
                      );
                    },
                    child: Text("Date PDF"),
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
                    child: Text("Generate Daily PDF"),
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
