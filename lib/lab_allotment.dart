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
              selectedDayPredicate: (day) =>
                  isSameDay(labController.selectedDate.value, day),
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
            child: Obx(() =>
                _buildAllotmentTable(labController.selectedDate.value)),
          ),
        ],
      ),
    );
  }

  // ===========================
  //    TABLE UI WITH MERGING
  // ===========================
  Widget _buildAllotmentTable(DateTime selectedDate) {
    final labs = [
      'L1', 'L2', 'L3', 'L4', 'L5', 'L6', 'L7', 'L8', 'L9', 'MP', 'PG LAB'
    ];

    final hours = ['H1', 'H2', 'H3', 'H4', 'LB', 'H5', 'H6', 'H7'];

    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];

    final dayString = dayNames[selectedDate.weekday - 1];
    final df = DateFormat('dd-MM-yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT COLUMN : LAB NAMES
          Column(
            children: [
              Container(
                width: 60,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all()),
                child: Text("Lab"),
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

          // MAIN TABLE
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HOURS HEADER
                  Row(
                    children: hours
                        .map((h) => Container(
                              width: 60,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(border: Border.all()),
                              child: Text(h),
                            ))
                        .toList(),
                  ),

                  // ROW FOR EACH LAB
                  ...labs.map((lab) {
                    final labEntries =
                        labController.labAllotments[lab] ?? [];

                    // FILTER VALID DAY ENTRIES
                    final dayEntries = labEntries.where((entry) {
                      try {
                        final s = df.parse(entry['start_date']);
                        final e = df.parse(entry['end_date']);
                        bool inRange =
                            selectedDate.isAfter(s.subtract(Duration(days: 1))) &&
                            selectedDate.isBefore(e.add(Duration(days: 1)));

                        return inRange && entry['day'] == dayString;
                      } catch (_) {
                        return false;
                      }
                    }).toList();

                    // ========================
                    //     MERGE HOURS
                    // ========================
                    final Map<String, List<int>> mergedGroups = {};

                    for (var e in dayEntries) {
                      String key =
                          "${e['class_name']}|${e['subject_name']}|${e['external']}|${e['start_date']}|${e['end_date']}";

                      int hr = int.tryParse(e['hours'] ?? '') ?? -1;

                      if (!mergedGroups.containsKey(key)) {
                        mergedGroups[key] = [];
                      }
                      mergedGroups[key]!.add(hr);
                    }

                    final mergedSlots = mergedGroups.entries.map((slot) {
                      final hoursList = slot.value..sort();
                      final parts = slot.key.split("|");

                      return {
                        "class": parts[0],
                        "subject": parts[1],
                        "external": parts[2],
                        "start": parts[3],
                        "end": parts[4],
                        "hours": hoursList,
                      };
                    }).toList();

                    // ========================
                    //     BUILD ROW CELLS
                    // ========================
                    return Row(
                      children: hours.map((hrText) {
                        final mapped = (hrText == "LB")
                            ? 8
                            : int.tryParse(hrText.replaceFirst("H", "")) ?? -1;

                        // FIND SLOT
                        Map<String, Object> found = mergedSlots.firstWhere(
                          (s) => (s["hours"] as List).contains(mapped),
                          orElse: () => {},
                        );

                        if (found.isEmpty) {
                          return emptyCell();
                        }

                        final hoursList = found["hours"] as List<int>;
                        final isStart = hoursList.first == mapped;

                        if (!isStart) {
                          return Container(width: 0, height: 40);
                        }

                        final span = hoursList.length;

                        return Container(
                          width: 60.0 * span,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(),
                            color: found["external"] == "external"
                                ? Colors.green[300]
                                : Colors.blue[200],
                          ),
                          child: Text(
                            "${found['class']} - ${found['subject']}",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
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

  Widget emptyCell() {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(border: Border.all()),
      child: const Text(""),
    );
  }
}
