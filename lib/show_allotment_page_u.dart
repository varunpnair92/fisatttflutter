import 'package:fisat_timetable/api_controller.dart';
import 'package:fisat_timetable/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fisat_timetable/lab_external.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShowAllotmentPageU extends StatefulWidget {
  @override
  _ShowAllotmentPageState createState() => _ShowAllotmentPageState();
}

class _ShowAllotmentPageState extends State<ShowAllotmentPageU> {
  final examController = Get.put(ExamController());
  DateTime? selectedDate = DateTime.now(); // ✅ Default to today's date
  bool isCheckBoxChecked = false;
  List<dynamic> freeLabSlots = [];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    examController.fetchLabExternal(); // ✅ Fetch normal allotments on load
  }

  Future<void> fetchFreeLabSlots() async {
    if (selectedDate == null) return;

    String formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate!);
    String apiUrl = '${Sharedvariable().ip}/lab/labdata_free';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": formattedDate}),
      );

      if (response.statusCode == 200) {
        setState(() {
          freeLabSlots = jsonDecode(response.body)['free_slots'];
        });
      } else {
        print('Error fetching free lab slots: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lab Allotments'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () async {
              DateTime now = DateTime.now();
              DateTime firstDate = DateTime(2025);
              DateTime lastDate = DateTime(2095, 12, 31);
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate:
                    (selectedDate != null && selectedDate!.isBefore(lastDate))
                        ? selectedDate!
                        : now.isAfter(lastDate)
                            ? lastDate
                            : now,
                firstDate: firstDate,
                lastDate: lastDate,
              );

              if (picked != null && mounted) {
                setState(() {
                  selectedDate = picked;
                });

                if (isCheckBoxChecked) {
                  fetchFreeLabSlots(); // Fetch free slots when checkbox is active
                }
              }
            },
          ),
          Row(
            children: [
              Text('Show Free Slots'),
              Checkbox(
                value: isCheckBoxChecked,
                onChanged: (bool? value) {
                  setState(() {
                    isCheckBoxChecked = value!;
                    if (isCheckBoxChecked) {
                      fetchFreeLabSlots();
                    } else {
                      freeLabSlots.clear();
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body:
          isCheckBoxChecked ? _buildFreeLabSlotsView() : _buildAllotmentsView(),
    );
  }

  Widget _buildFreeLabSlotsView() {
    if (freeLabSlots.isEmpty) {
      return Center(child: Text('No free lab slots available'));
    }

    return ListView.builder(
      itemCount: freeLabSlots.length,
      itemBuilder: (context, index) {
        final slot = freeLabSlots[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text('Lab: ${slot["lab_name"]}'),
            subtitle: Text('Free Hours: ${slot["hours_free"]}'),
          ),
        );
      },
    );
  }

  Widget _buildAllotmentsView() {
    return Obx(() {
      if (examController.apiData.isEmpty) {
        return Center(child: Text('No allotments available'));
      }

      List<Labexternal> sortedAllotments =
          _extractAndSortAllotments(examController.apiData);
      List<Labexternal> filteredAllotments =
          _filterAllotmentsByDate(sortedAllotments);

      if (filteredAllotments.isEmpty) {
        return Center(
            child: Text('No allotments available for the selected date'));
      }

      return ListView.builder(
        itemCount: filteredAllotments.length,
        itemBuilder: (context, index) {
          final allotment = filteredAllotments[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              title: Text('Date: ${allotment.startDate}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Lab: ${allotment.labName}'),
                  Text('Class: ${allotment.className}'),
                  Text('Subject: ${allotment.subjectName}'),
                  Text('Hours: ${allotment.hoursAllotted}'),
                ],
              ),

              // ✅ LONG PRESS FUNCTION ADDED HERE
              onLongPress: () {
                String copyText = "Date: ${allotment.startDate}\n"
                    "Lab: ${allotment.labName}\n"
                    "Class: ${allotment.className}\n"
                    "Subject: ${allotment.subjectName}\n"
                    "Hours: ${allotment.hoursAllotted}";

                // Copy to clipboard
                Clipboard.setData(ClipboardData(text: copyText));

                // Toast / SnackBar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Copied to clipboard")),
                );
              },
            ),
          );
        },
      );
    });
  }

  List<Labexternal> _extractAndSortAllotments(List<Labexternal> allotments) {
    try {
      allotments.sort((a, b) {
        DateTime dateA = DateFormat('dd-MM-yyyy').parse(a.startDate);
        DateTime dateB = DateFormat('dd-MM-yyyy').parse(b.startDate);
        return dateB.compareTo(dateA); // Latest date first
      });
    } catch (e) {}
    return allotments;
  }

  List<Labexternal> _filterAllotmentsByDate(List<Labexternal> allotments) {
    if (selectedDate == null) return allotments;
    return allotments.where((allotment) {
      DateTime allotmentDate =
          DateFormat('dd-MM-yyyy').parse(allotment.startDate);
      return allotmentDate.isAtSameMomentAs(selectedDate!);
    }).toList();
  }

  void _showDeleteConfirmationDialog(int id) {
    Get.defaultDialog(
      title: "Delete Allotment",
      middleText: "Are you sure you want to delete this allotment?",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        examController.deleteAllotment(id);
        Get.back(); // Close dialog
      },
    );
  }
}
