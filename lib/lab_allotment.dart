import 'package:fisat_timetable/lab_controller.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class LabAllotmentPage extends StatelessWidget {
  LabAllotmentPage({super.key});

  final LabController labController = Get.put(LabController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 35),

          // ================= CALENDAR =================
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
                labController.changeCalendarFormat(format);
              },
              onPageChanged: (focusedDay) {
                labController.selectDate(focusedDay);
              },
            );
          }),

          // ================= TABLE =================
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Obx(() {
                  return _buildAllotmentTable(
                    labController.selectedDate.value,
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ======================================================
  //            RESPONSIVE MERGED ALLOTMENT TABLE
  // ======================================================
  Widget _buildAllotmentTable(
      DateTime selectedDate, double maxWidth, double maxHeight) {
    final labs = [
      'L1', 'L2', 'L3', 'L4', 'L5',
      'L6', 'L7', 'L8', 'L9', 'MP', 'PG LAB'
    ];

    final hours = ['H1', 'H2', 'H3', 'H4', 'LB', 'H5', 'H6', 'H7'];

    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    final dayString = dayNames[selectedDate.weekday - 1];
    final df = DateFormat('dd-MM-yyyy');

    // ---------- DYNAMIC SIZE ----------
    final cellWidth =
        (maxWidth / (hours.length + 1)).clamp(55.0, 110.0);
    final cellHeight =
        (maxHeight / (labs.length + 3)).clamp(36.0, 55.0);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= LAB COLUMN =================
          Column(
            children: [
              _cell("Lab", cellWidth, cellHeight, header: true),
              ...labs.map((lab) =>
                  _cell(lab == "PG LAB" ? "PG" : lab, cellWidth, cellHeight)),
            ],
          ),

          // ================= MAIN GRID =================
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------- HOURS HEADER --------
                  Row(
                    children: hours
                        .map((h) =>
                            _cell(h, cellWidth, cellHeight, header: true))
                        .toList(),
                  ),

                  // -------- LAB ROWS --------
                  ...labs.map((lab) {
                    final labEntries =
                        labController.labAllotments[lab] ?? [];

                    // ---- FILTER BY DAY & DATE RANGE ----
                    final dayEntries = labEntries.where((e) {
                      try {
                        final s = df.parse(e['start_date']);
                        final ed = df.parse(e['end_date']);
                        return selectedDate
                                .isAfter(s.subtract(const Duration(days: 1))) &&
                            selectedDate
                                .isBefore(ed.add(const Duration(days: 1))) &&
                            e['day'] == dayString;
                      } catch (_) {
                        return false;
                      }
                    }).toList();

                    // ---- MERGE HOURS ----
                    final Map<String, List<int>> merged = {};

                    for (var e in dayEntries) {
                      final key =
                          "${e['class_name']}|${e['subject_name']}|${e['external']}|${e['start_date']}|${e['end_date']}";
                      final hr = int.tryParse(e['hours'] ?? '') ?? -1;
                      merged.putIfAbsent(key, () => []).add(hr);
                    }

                    final slots = merged.entries.map((m) {
                      final parts = m.key.split("|");
                      m.value.sort();
                      return {
                        "class": parts[0],
                        "subject": parts[1],
                        "external": parts[2],
                        "hours": m.value,
                      };
                    }).toList();

                    // ---- BUILD ROW ----
                    return Row(
                      children: hours.map((h) {
                        final mapped =
                            (h == "LB") ? 8 : int.parse(h.substring(1));

                        final slot = slots.firstWhere(
                          (s) => (s["hours"] as List<int>).contains(mapped),
                          orElse: () => {},
                        );

                        if (slot.isEmpty) {
                          return _emptyCell(cellWidth, cellHeight);
                        }

                        final hrs = slot["hours"] as List<int>;
                        if (hrs.first != mapped) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          width: cellWidth * hrs.length,
                          height: cellHeight,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(),
                            color: slot["external"] == "external"
                                ? Colors.green[300]
                                : Colors.blue[200],
                          ),
                          child: Text(
                            "${slot['class']} - ${slot['subject']}",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
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

  // ================= HELPER WIDGETS =================
  Widget _cell(String text, double w, double h, {bool header = false}) {
    return Container(
      width: w,
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all()),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _emptyCell(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(border: Border.all()),
    );
  }
}
