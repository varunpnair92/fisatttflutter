import 'package:fisat_timetable/laballotment_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'lab_controller.dart'; // Import your controller
import 'package:http/http.dart' as http;
import 'dart:convert';

class SaveAllotmentPage extends StatelessWidget {
  final LabController labController = Get.put(LabController());
  final _formKey = GlobalKey<FormState>();

  // Create TextEditingControllers for date fields
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Update the controllers with values from labController
    _startDateController.text = labController.formData['start_date'] ?? '';
    _endDateController.text = labController.formData['end_date'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Save Allotment'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Lab Name'),
                items: [
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
                ].map((lab) {
                  return DropdownMenuItem<String>(
                    value: lab,
                    child: Text(lab),
                  );
                }).toList(),
                onChanged: (value) {
                  labController.formData.update('lab_name', (_) => value ?? '');
                },
                validator: (value) =>
                    value == null ? 'Please select a lab' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Hours Allotted'),
                onChanged: (value) {
                  labController.formData.update('hours_allotted', (_) => value);
                },
                validator: (value) =>
                    value!.isEmpty ? 'Please enter hours allotted' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject Name'),
                onChanged: (value) {
                  labController.formData.update('subject_name', (_) => value);
                },
                validator: (value) =>
                    value!.isEmpty ? 'Please enter subject name' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Class Name'),
                onChanged: (value) {
                  labController.formData.update('class_name', (_) => value);
                },
                validator: (value) =>
                    value!.isEmpty ? 'Please enter class name' : null,
              ),
              TextFormField(
                readOnly: true,
                controller: _startDateController,
                decoration:
                    InputDecoration(labelText: 'Start Date (dd-MM-yyyy)'),
                onTap: () => _selectDate(context, 'start_date'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter start date';
                  }
                  try {
                    DateFormat('dd-MM-yyyy').parse(value);
                  } catch (e) {
                    return 'Invalid date format';
                  }
                  return null;
                },
              ),
              TextFormField(
                readOnly: true,
                controller: _endDateController,
                decoration: InputDecoration(labelText: 'End Date (dd-MM-yyyy)'),
                onTap: () => _selectDate(context, 'end_date'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter end date';
                  }
                  try {
                    DateFormat('dd-MM-yyyy').parse(value);
                  } catch (e) {
                    return 'Invalid date format';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text('Allot:'),
              ListTile(
                title: const Text('Continue'),
                leading: Radio<String>(
                  value: 'continue',
                  groupValue: labController.formData['allot'],
                  onChanged: (value) {
                    labController.formData.update('allot', (_) => value!);
                  },
                ),
              ),
              ListTile(
                title: const Text('Repeat'),
                leading: Radio<String>(
                  value: 'repeat',
                  groupValue: labController.formData['allot'],
                  onChanged: (value) {
                    labController.formData.update('allot', (_) => value!);
                  },
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    labController.saveData();
                  }
                },
                child: Text('Save'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_startDateController.text.isNotEmpty) {
                    await _generateReport();
                  } else {
                    // Show an error if the start date is not selected
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Please select a start date first.')),
                    );
                  }
                },
                child: Text('Generate Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, String dateType) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (selectedDate != null) {
      final formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
      labController.formData.update(dateType, (_) => formattedDate);
      if (dateType == 'start_date') {
        _startDateController.text = formattedDate;
      } else if (dateType == 'end_date') {
        _endDateController.text = formattedDate;
      }
    }
  }

  Future<void> _generateReport() async {
    DateTime startDate =
        DateFormat('dd-MM-yyyy').parse(_startDateController.text);
    DateTime endDate=DateFormat('dd-MM-yyyy').parse(_endDateController.text);

    // Fetch the lab allotments for the start date
    await labController.fetchLabAllotmentsForRange(startDate,endDate);
    Get.to(LabAllotmentsReport());
  }
}
