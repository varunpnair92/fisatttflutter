import 'package:fisat_timetable/lab_controller.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LabAllotmentPage extends StatelessWidget {
  final LabController labController = Get.put(LabController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(height: 35),
          Obx(() {
            return TableCalendar(
              firstDay: DateTime.utc(2025, 1, 1),
              lastDay: DateTime.utc(2095, 12, 31),
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
            child: Obx(
              () => _buildAllotmentTable(labController.selectedDate.value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllotmentTable(DateTime selectedDate) {
    final labs = [
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
      'PG LAB',
    ];

    final hours = ['H1', 'H2', 'H3', 'H4', 'LB', 'H5', 'H6', 'H7'];

    final dayNames = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final dayString = dayNames[selectedDate.weekday - 1];
    final DateFormat dateFormat = DateFormat('dd-MM-yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LAB COLUMN
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all()),
                child: Text('Lab'),
              ),
              ...labs.map((lab) => Container(
                    width: 60,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all()),
                    child: Text(lab == "PG LAB" ? "PG" : lab),
                  )),
            ],
          ),

          // SCROLLABLE TABLE
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HOURS HEADER
                  Row(
                    children: hours
                        .map(
                          (hour) => Container(
                            width: 60,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(border: Border.all()),
                            child: Text(hour),
                          ),
                        )
                        .toList(),
                  ),

                  // DATA ROWS
                  ...labs.map((lab) {
                    final labEntries = labController.labAllotments[lab] ?? [];

                    final dayEntries = labEntries.where((entry) {
                      try {
                        final startDate =
                            dateFormat.parse(entry['start_date'] ?? '');
                        final endDate =
                            dateFormat.parse(entry['end_date'] ?? '');
                        bool dateInRange =
                            selectedDate.isAfter(startDate.subtract(
                                    Duration(days: 1))) &&
                                selectedDate
                                    .isBefore(endDate.add(Duration(days: 1)));
                        bool correctDay = entry['day'] == dayString;
                        return dateInRange && correctDay;
                      } catch (e) {
                        print("Date error: $e");
                        return false;
                      }
                    }).toList();

                    return Row(
                      children: hours.map((hour) {
                        final mappedHour =
                            hour == 'LB' ? '8' : hour.replaceFirst('H', '');
                        final matchingEntries = dayEntries.where((entry) {
                          final entryHours = entry['hours']
                              ?.split(',')
                              .map((e) => e.trim())
                              .toList();
                          return entryHours?.contains(mappedHour) ?? false;
                        }).toList();

                        // NEW: check external allotment
                        final isExternal = matchingEntries
                            .any((e) => e['external'] == 'external');

                        final cellContent = matchingEntries.isNotEmpty
                            ? matchingEntries
                                .map((entry) =>
                                    '${entry['class_name']} - ${entry['subject_name']}')
                                .join('\n')
                            : '';

                        return Container(
                          width: 60,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(),

                            // NEW COLORING RULE
                            color: matchingEntries.isNotEmpty
                                ? (isExternal
                                    ? Colors.green[200] // external → green
                                    : Colors.blue[100]) // normal → blue
                                : null,
                          ),
                          child: Text(cellContent),
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
