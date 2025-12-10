import 'package:fisat_timetable/daily_report_pdf.dart';
import 'package:fisat_timetable/laballotment_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'lab_controller.dart';

class SaveAllotmentPage extends StatelessWidget {
  final LabController labController = Get.put(LabController());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final List<String> labNames = [
    'L1', 'L2', 'L3', 'L4', 'L5',
    'L6', 'L7', 'L8', 'L9', 'MP', 'PG'
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

              // ✅ LAB NAME
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Lab Name'),
                items: labNames
                    .map((lab) => DropdownMenuItem(value: lab, child: Text(lab)))
                    .toList(),
                onChanged: (value) =>
                    labController.formData['lab_name'] = value ?? '',
                validator: (value) => value == null ? 'Please select a lab' : null,
              ),

              SizedBox(height: 16),

              // ✅ FROM / TO HOUR
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'From Hour'),
                      items: hoursList
                          .map((hour) => DropdownMenuItem(
                                value: hour,
                                child: Text(hour),
                              ))
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
                          .map((hour) => DropdownMenuItem(
                                value: hour,
                                child: Text(hour),
                              ))
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

              // ✅ SUBJECT
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject Name'),
                onChanged: (value) =>
                    labController.formData['subject_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter subject name' : null,
              ),

              SizedBox(height: 16),

              // ✅ CLASS
              TextFormField(
                decoration: InputDecoration(labelText: 'Class Name'),
                onChanged: (value) =>
                    labController.formData['class_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter class name' : null,
              ),

              SizedBox(height: 16),

              // ✅ START DATE
              _buildDateField(
                'Start Date',
                _startDateController,
                'start_date',
                context,
              ),

              SizedBox(height: 16),

              // ✅ END DATE
              _buildDateField(
                'End Date',
                _endDateController,
                'end_date',
                context,
              ),

              SizedBox(height: 20),

              // ✅ ✅ ✅ RADIO BUTTONS (PURE UI CONTROLLED)
              Text('Allot:'),

              Obx(() => ListTile(
                    title: const Text('Continue'),
                    leading: Radio<String>(
                      value: 'continue',
                      groupValue: labController.formData['allot'],
                      onChanged: (value) {
                        labController.formData['allot'] = value!;
                      },
                    ),
                  )),

              Obx(() => ListTile(
                    title: const Text('Repeat'),
                    leading: Radio<String>(
                      value: 'repeat',
                      groupValue: labController.formData['allot'],
                      onChanged: (value) {
                        labController.formData['allot'] = value!;
                      },
                    ),
                  )),

              SizedBox(height: 20),

              // ✅ SAVE BUTTON
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {

                    // ✅ Ensure radio is selected
                    if (!labController.formData.containsKey('allot')) {
                      Get.snackbar("Error", "Please select Continue or Repeat");
                      return;
                    }

                    final fromHour = labController.formData['from_hour'];
                    final toHour = labController.formData['to_hour'];

                    if (fromHour != null && toHour != null) {
                      final fromIndex = hoursList.indexOf(fromHour);
                      final toIndex = hoursList.indexOf(toHour);

                      if (fromIndex <= toIndex) {
                        final selectedHours = hoursList
                            .sublist(fromIndex, toIndex + 1)
                            .map((h) => h == 'LB' ? '8' : h)
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
                          'Invalid Range',
                          'From hour must be ≤ To hour',
                        );
                      }
                    }
                  }
                },
                child: Text('Save'),
              ),

              SizedBox(height: 20),

              // ✅ REPORT BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      if (_startDateController.text.isNotEmpty &&
                          _endDateController.text.isNotEmpty) {
                        await labController.fetchLabAllotmentsForRange(
                          DateFormat('dd-MM-yyyy')
                              .parse(_startDateController.text),
                          DateFormat('dd-MM-yyyy')
                              .parse(_endDateController.text),
                        );
                        Get.to(LabAllotmentsReport());
                      } else {
                        Get.snackbar(
                          'Error',
                          'Please select both start & end dates.',
                        );
                      }
                    },
                    child: Text('Generate Report'),
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      if (_startDateController.text.isEmpty) {
                        Get.snackbar(
                          "Error",
                          "Please select Start Date first.",
                        );
                        return;
                      }

                      DateTime date = DateFormat('dd-MM-yyyy')
                          .parse(_startDateController.text);

                      await labController.fetchLabAllotmentsForDate(date);

                      await DailyGridPdfGenerator.generate(
                        date: date,
                        labController: labController,
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

  // ✅ DATE PICKER FIELD
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
          final formattedDate =
              DateFormat('dd-MM-yyyy').format(selectedDate);

          labController.formData[field] = formattedDate;
          controller.text = formattedDate;
        }
      },
      validator: (value) =>
          value!.isEmpty ? 'Please select $label' : null,
    );
  }
}
