import 'package:fisat_timetable/lab_controller.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart'; // Import intl package

class LabAllotmentPage extends StatelessWidget {
  final LabController labController = Get.put(LabController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lab Allotment'),
      ),
      body: Column(
        children: <Widget>[
          Obx(() {
            return TableCalendar(
              firstDay: DateTime.utc(2024, 8, 1),
              lastDay: DateTime.utc(2024, 12, 31),
              focusedDay: labController.selectedDate.value,
              calendarFormat: labController.calendarFormat.value,
              selectedDayPredicate: (day) {
                return isSameDay(labController.selectedDate.value, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                labController.selectDate(selectedDay);
              },
              onFormatChanged: (format) {
                if (labController.calendarFormat.value != format) {
                  labController.changeCalendarFormat(format);
                }
              },
              onPageChanged: (focusedDay) {
                labController.selectDate(focusedDay);
              },
            );
          }),
          Expanded(
            child: Obx(() => _buildAllotmentTable(labController.selectedDate.value)),
          ),
        ],
      ),
    );
  }

  Widget _buildAllotmentTable(DateTime selectedDate) {
    final labs = ['L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'MP LAB', 'PG LAB'];
    final hours = ['H1', 'H2', 'H3', 'H4', 'LB', 'H5', 'H6', 'H7'];

    // Convert selectedDate to a day string
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    final dayString = dayNames[selectedDate.weekday - 1]; // Full day name
    
    // Date format to use for parsing
    final DateFormat dateFormat = DateFormat('dd-MM-yyyy');
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header Row for Hours
            Table(
              border: TableBorder.all(),
              columnWidths: {
                0: FixedColumnWidth(100), // Lab name column width
                for (int i = 1; i < hours.length + 1; i++) i: FixedColumnWidth(50), // Hours column width
              },
              children: [
                TableRow(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(),
                      ),
                      child: Text('Lab/Hours'),
                    ),
                    ...hours.map((hour) => Container(
                      alignment: Alignment.center,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(),
                      ),
                      child: Text(hour),
                    )).toList(),
                  ],
                ),
                // Data Rows
                ...labs.map((lab) {
                  final labEntries = labController.labAllotments[lab] ?? [];
                  
                  // Filter entries based on the selected date
                  final dayEntries = labEntries.where((entry) {
                    try {
                      final startDate = dateFormat.parse(entry['start_date'] ?? '');
                      final endDate = dateFormat.parse(entry['end_date'] ?? '');
                      bool dateInRange = selectedDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                                         selectedDate.isBefore(endDate.add(Duration(days: 1)));
                      bool correctDay = entry['day'] == dayString;
                      
                      // Debug output
                      print('Start Date: $startDate, End Date: $endDate, Selected Date: $selectedDate, Day: $dayString');
                      print('In Range: $dateInRange, Correct Day: $correctDay');

                      return dateInRange && correctDay;
                    } catch (e) {
                      // Handle any parsing errors
                      print('Date parsing error: $e');
                      return false;
                    }
                  }).toList();

                  List<Widget> hourCells = List.generate(hours.length, (index) {
                    final hour = hours[index];
                    final hourNumber = hour.replaceFirst('H', '');
                    final matchingEntries = dayEntries.where((entry) {
                      final entryHours = entry['hours']?.split(',').map((e) => e.trim()).toList();
                      return entryHours?.contains(hourNumber) ?? false;
                    }).toList();

                    final cellContent = matchingEntries.isNotEmpty
                        ? matchingEntries.map((entry) {
                            return '${entry['class_name']} - ${entry['subject_name']}';
                          }).join('\n')
                        : '';

                    return Container(
                      alignment: Alignment.center,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(),
                        color: matchingEntries.isNotEmpty ? Colors.blue[100] : null,
                      ),
                      child: Text(cellContent),
                    );
                  });

                  // Merge cells based on hours
                  List<Widget> mergedHourCells = [];
                  int index = 0;

                  while (index < hours.length) {
                    final hour = hours[index];
                    final hourNumber = hour.replaceFirst('H', '');
                    final matchingEntries = dayEntries.where((entry) {
                      final entryHours = entry['hours']?.split(',').map((e) => e.trim()).toList();
                      return entryHours?.contains(hourNumber) ?? false;
                    }).toList();

                    final cellContent = matchingEntries.isNotEmpty
                        ? matchingEntries.map((entry) {
                            return '${entry['class_name']} - ${entry['subject_name']}';
                          }).join('\n')
                        : '';

                    if (cellContent.isNotEmpty) {
                      int mergeEnd = index;

                      // Determine the end index for merging
                      while (mergeEnd + 1 < hours.length &&
                             dayEntries.any((entry) {
                               final entryHours = entry['hours']?.split(',').map((e) => e.trim()).toList();
                               return entryHours?.contains(hours[mergeEnd + 1].replaceFirst('H', '')) ?? false;
                             }) &&
                             cellContent == hourCells[mergeEnd].toString()) {
                        mergeEnd++;
                      }

                      // Add the merged cell
                      mergedHourCells.add(
                        _buildMergedCell(cellContent, mergeEnd - index + 1),
                      );

                      index = mergeEnd + 1;
                    } else {
                      mergedHourCells.add(_buildEmptyCell());
                      index++;
                    }
                  }

                  return TableRow(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(),
                        ),
                        child: Text(lab),
                      ),
                      ...mergedHourCells,
                    ],
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMergedCell(String content, int colspan) {
    return Container(
      alignment: Alignment.center,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(),
        color: Colors.blue[100],
      ),
      child: Text(content),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      alignment: Alignment.center,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(),
      ),
      child: SizedBox.shrink(),
    );
  }
}
