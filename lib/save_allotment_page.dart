import 'package:fisat_timetable/laballotment_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'lab_controller.dart'; // Import your controller

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

  final List<String> hoursList = ['1', '2', '3', '4', '8', '5', '6', '7'];

  @override
  Widget build(BuildContext context) {
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
              // Lab Name Dropdown
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Lab Name'),
                items: labNames
                    .map(
                        (lab) => DropdownMenuItem(value: lab, child: Text(lab)))
                    .toList(),
                onChanged: (value) =>
                    labController.formData['lab_name'] = value ?? '',
                validator: (value) =>
                    value == null ? 'Please select a lab' : null,
              ),
              SizedBox(height: 16),

              // Hour Range Dropdown
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

              // Subject Name Input
              TextFormField(
                decoration: InputDecoration(labelText: 'Subject Name'),
                onChanged: (value) =>
                    labController.formData['subject_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter subject name' : null,
              ),

              SizedBox(height: 16),

              // Class Name Input
              TextFormField(
                decoration: InputDecoration(labelText: 'Class Name'),
                onChanged: (value) =>
                    labController.formData['class_name'] = value,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter class name' : null,
              ),

              SizedBox(height: 16),

              // Date Pickers
              _buildDateField(
                  'Start Date', _startDateController, 'start_date', context),
              SizedBox(height: 16),
              _buildDateField(
                  'End Date', _endDateController, 'end_date', context),

              SizedBox(height: 20),

              // Save Button with Hour Conversion
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final fromHour = labController.formData['from_hour'];
                    final toHour = labController.formData['to_hour'];

                    if (fromHour != null && toHour != null) {
                      // Get the index positions in the custom hour order
                      final fromIndex = hoursList.indexOf(fromHour);
                      final toIndex = hoursList.indexOf(toHour);

                      if (fromIndex <= toIndex) {
                        // Generate the range based on index positions
                        final selectedHours =
                            hoursList.sublist(fromIndex, toIndex + 1);
                        labController.formData['hours_allotted'] =
                            selectedHours.join(',');

                        // Clear from and to hour after converting
                        labController.formData.remove('from_hour');
                        labController.formData.remove('to_hour');

                        // Save the data
                        labController.saveData();
                      } else {
                        Get.snackbar('Invalid Range',
                            'From hour must be less than or equal to To hour');
                      }
                    }
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller,
      String field, BuildContext context) {
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
          final formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
          labController.formData[field] = formattedDate;
          controller.text = formattedDate;
        }
      },
      validator: (value) => value!.isEmpty ? 'Please select $label' : null,
    );
  }
}
