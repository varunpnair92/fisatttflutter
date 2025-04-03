import 'package:fisat_timetable/api_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fisat_timetable/lab_external.dart';

class ShowAllotmentPage extends StatefulWidget {
  @override
  _ShowAllotmentPageState createState() => _ShowAllotmentPageState();
}

class _ShowAllotmentPageState extends State<ShowAllotmentPage> {
  final examController = Get.put(ExamController());
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    examController. fetchLabExternal(); // ✅ Fetch allotments on page load
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
              DateTime firstDate = DateTime(2023);
              DateTime lastDate = DateTime(2025, 12, 31);

              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: (selectedDate != null && selectedDate!.isBefore(lastDate))
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
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        if (examController.apiData.isEmpty) {
          return Center(child: Text('No allotments available'));
        }

        List<Labexternal> sortedAllotments = _extractAndSortAllotments(examController.apiData);
        List<Labexternal> filteredAllotments = _filterAllotmentsByDate(sortedAllotments);

        if (filteredAllotments.isEmpty) {
          return Center(child: Text('No allotments available for the selected date'));
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
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    print("Delete button clicked for ID: ${allotment.id}");
                    _showDeleteConfirmationDialog(allotment.id);
                  },
                ),
              ),
            );
          },
        );
      }),
    );
  }

  List<Labexternal> _extractAndSortAllotments(List<Labexternal> allotments) {
    try {
      allotments.sort((a, b) {
        DateTime dateA = DateFormat('dd-MM-yyyy').parse(a.startDate);
        DateTime dateB = DateFormat('dd-MM-yyyy').parse(b.startDate);
        return dateB.compareTo(dateA); // Latest date first
      });
    } catch (e) {
      print('Error sorting dates: $e');
    }
    return allotments;
  }

  List<Labexternal> _filterAllotmentsByDate(List<Labexternal> allotments) {
    if (selectedDate == null) return allotments;
    return allotments.where((allotment) {
      DateTime allotmentDate = DateFormat('dd-MM-yyyy').parse(allotment.startDate);
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
