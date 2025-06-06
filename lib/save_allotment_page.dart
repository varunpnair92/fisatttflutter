import 'package:fisat_timetable/laballotment_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'lab_controller.dart';

class SaveAllotmentPage extends StatefulWidget {
  @override
  _SaveAllotmentPageState createState() => _SaveAllotmentPageState();
}

class _SaveAllotmentPageState extends State<SaveAllotmentPage> {
  final LabController labController = Get.put(LabController());
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  final List<String> labNames = [
    'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'MP', 'PG'
  ];

  // Original list: '1' to '7' for periods, '8' for LB (Library)
  final List<String> hoursList = ['1', '2', '3', '4', '8','5', '6', '7'];

  String? selectedLab;
  String? fromHour;
  String? toHour;
  String allotOption = "continue";

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _classController = TextEditingController();

  void _resetForm() {
    setState(() {
      selectedLab = null;
      fromHour = null;
      toHour = null;
      allotOption = 'continue';
      _subjectController.clear();
      _classController.clear();
      _startDateController.clear();
      _endDateController.clear();

      labController.formData.value = {
        "lab_name": "",
        "hours_allotted": "",
        "subject_name": "",
        "class_name": "",
        "start_date": "",
        "end_date": "",
        "allot": "continue",
        "external": "external",
      };
    });
  }

  @override
  Widget build(BuildContext context) {
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
                value: selectedLab,
                decoration: InputDecoration(labelText: 'Lab Name'),
                items: labNames.map((lab) => DropdownMenuItem(value: lab, child: Text(lab))).toList(),
                onChanged: (value) {
                  setState(() => selectedLab = value);
                  labController.formData['lab_name'] = value ?? '';
                },
                validator: (value) => value == null ? 'Please select a lab' : null,
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: fromHour,
                      decoration: InputDecoration(labelText: 'From Hour'),
                      items: hoursList.map((hour) => DropdownMenuItem(value: hour, child: Text(hour == '8' ? 'LB' : hour))).toList(),
                      onChanged: (value) {
                        setState(() => fromHour = value);
                        labController.formData['from_hour'] = value ?? '';
                      },
                      validator: (value) => value == null ? 'Select from hour' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: toHour,
                      decoration: InputDecoration(labelText: 'To Hour'),
                      items: hoursList.map((hour) => DropdownMenuItem(value: hour, child: Text(hour == '8' ? 'LB' : hour))).toList(),
                      onChanged: (value) {
                        setState(() => toHour = value);
                        labController.formData['to_hour'] = value ?? '';
                      },
                      validator: (value) => value == null ? 'Select to hour' : null,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(labelText: 'Subject Name'),
                onChanged: (value) => labController.formData['subject_name'] = value,
                validator: (value) => value!.isEmpty ? 'Please enter subject name' : null,
              ),

              SizedBox(height: 16),

              TextFormField(
                controller: _classController,
                decoration: InputDecoration(labelText: 'Class Name'),
                onChanged: (value) => labController.formData['class_name'] = value,
                validator: (value) => value!.isEmpty ? 'Please enter class name' : null,
              ),

              SizedBox(height: 16),

              _buildDateField('Start Date', _startDateController, 'start_date'),
              SizedBox(height: 16),
              _buildDateField('End Date', _endDateController, 'end_date'),

              SizedBox(height: 20),

              Text('Allot:'),
              ListTile(
                title: const Text('Continue'),
                leading: Radio<String>(
                  value: 'continue',
                  groupValue: allotOption,
                  onChanged: (value) {
                    setState(() => allotOption = value!);
                    labController.formData['allot'] = value!;
                  },
                ),
              ),
              ListTile(
                title: const Text('Repeat'),
                leading: Radio<String>(
                  value: 'repeat',
                  groupValue: allotOption,
                  onChanged: (value) {
                    setState(() => allotOption = value!);
                    labController.formData['allot'] = value!;
                  },
                ),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final fromIndex = hoursList.indexOf(fromHour!);
                    final toIndex = hoursList.indexOf(toHour!);

                    if (fromIndex <= toIndex) {
                      final selectedHours = hoursList.sublist(fromIndex, toIndex + 1);
                      labController.formData['hours_allotted'] = selectedHours.join(',');
                      labController.formData.remove('from_hour');
                      labController.formData.remove('to_hour');

                      labController.saveData().then((_) {
                        _resetForm(); // Clear form after save
                      });
                    } else {
                      Get.snackbar('Invalid Range', 'From hour must be less than or equal to To hour');
                    }
                  }
                },
                child: Text('Save'),
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (_startDateController.text.isNotEmpty &&
                      _endDateController.text.isNotEmpty) {
                    await labController.fetchLabAllotmentsForRange(
                      DateFormat('dd-MM-yyyy').parse(_startDateController.text),
                      DateFormat('dd-MM-yyyy').parse(_endDateController.text),
                    );
                    Get.to(LabAllotmentsReport());
                  } else {
                    Get.snackbar('Error', 'Please select both start and end dates.');
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

  Widget _buildDateField(String label, TextEditingController controller, String field) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      decoration: InputDecoration(labelText: label),
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        );

        if (pickedDate != null) {
          final formatted = DateFormat('dd-MM-yyyy').format(pickedDate);
          setState(() {
            controller.text = formatted;
            labController.formData[field] = formatted;
          });
        }
      },
      validator: (value) => value!.isEmpty ? 'Please select $label' : null,
    );
  }
}
