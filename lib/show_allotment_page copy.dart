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
              DateTime lastDate = DateTime(2025, 12, 31);

              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: (selectedDate != null && selectedDate!.isBefore(lastDate))
                    ? selectedDate!
                    : now.isAfter(lastDate)
                        ? lastDate
                        : now,  // Ensures initialDate is within range
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
      body: Center(
        child: Obx(() {
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
                      Text('Class: ${allotment.className}'),
                      Text('Subject: ${allotment.subjectName}'),
                      Text('Hours: ${allotment.hoursAllotted}'),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
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
      return allotmentDate == selectedDate;
    }).toList();
  }
}
