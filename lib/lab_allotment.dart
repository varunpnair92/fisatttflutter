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
            child: Obx(
              () => _buildAllotmentTable(labController.selectedDate.value),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  //                   TABLE UI
  // =====================================================
  Widget _buildAllotmentTable(DateTime selectedDate) {
    final labs = [
      'L1','L2','L3','L4','L5','L6','L7','L8','L9','MP','PG LAB'
    ];

    final hours = ['H1','H2','H3','H4','LB','H5','H6','H7'];

    final dayNames = [
      'Monday','Tuesday','Wednesday',
      'Thursday','Friday','Saturday','Sunday'
    ];

    final dayString = dayNames[selectedDate.weekday - 1];
    final df = DateFormat('dd-MM-yyyy');

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // =============== LAB COLUMN ===============
          Column(
            children: [
              _headerCell("Lab"),
              ...labs.map((lab) => _cell(lab == "PG LAB" ? "PG" : lab)),
            ],
          ),

          // =============== MAIN GRID ===============
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [

                  // ---------- HOURS HEADER ----------
                  Row(
                    children: hours.map((h) => _headerCell(h)).toList(),
                  ),

                  // ---------- EACH LAB ----------
                  ...labs.map((lab) {
                    final labEntries =
                        labController.labAllotments[lab] ?? [];

                    // FILTER DATE + DAY
                    final dayEntries = labEntries.where((e) {
                      try {
                        final s = df.parse(e['start_date']);
                        final en = df.parse(e['end_date']);
                        return selectedDate
                                .isAfter(s.subtract(const Duration(days: 1))) &&
                            selectedDate
                                .isBefore(en.add(const Duration(days: 1))) &&
                            e['day'] == dayString;
                      } catch (_) {
                        return false;
                      }
                    }).toList();

                    // ====================================================
                    //      MERGE HOURS  (FINAL — CUSTOM ORDER LOGIC)
                    // ====================================================
                    final Map<String, List<int>> grouped = {};

                    for (var e in dayEntries) {
                      final key =
                          "${e['class_name']}|${e['subject_name']}|${e['external']}";

                      int hr = int.tryParse(e['hours'] ?? '') ?? -1;

                      grouped.putIfAbsent(key, () => []);
                      grouped[key]!.add(hr);
                    }

                    // YOUR ORDER → 8 sits between 4 & 5
                    final order = [1,2,3,4,8,5,6,7];

                    final List<Map<String,dynamic>> mergedSlots = [];

                    grouped.forEach((key, list) {
                      final parts = key.split("|");

                      list.sort((a,b) =>
                          order.indexOf(a).compareTo(order.indexOf(b)));

                      List<int> block = [list.first];

                      for (int i = 1; i < list.length; i++) {
                        final prev = block.last;
                        final curr = list[i];

                        final prevIndex = order.indexOf(prev);
                        final currIndex = order.indexOf(curr);

                        final isContiguous =
                            currIndex == prevIndex + 1;

                        if (isContiguous) {
                          block.add(curr);
                        } else {
                          mergedSlots.add({
                            "class": parts[0],
                            "subject": parts[1],
                            "external": parts[2],
                            "hours": List<int>.from(block),
                          });
                          block = [curr];
                        }
                      }

                      mergedSlots.add({
                        "class": parts[0],
                        "subject": parts[1],
                        "external": parts[2],
                        "hours": List<int>.from(block),
                      });
                    });

                    // -------- BUILD ROW --------
                    return Row(
                      children: hours.map((hText) {
                        final mapped =
                            hText == "LB" ? 8 : int.parse(hText.substring(1));

                        final found = mergedSlots.firstWhere(
                          (s) => (s['hours'] as List).contains(mapped),
                          orElse: () => {},
                        );

                        if (found.isEmpty) return _cell("");

                        final hrs = found['hours'] as List<int>;
                        if (hrs.first != mapped) {
                          return const SizedBox(width: 0, height: 40);
                        }

                        final span = hrs.length;

                        // ================= LONG PRESS FREE =================
                        return GestureDetector(
                          onLongPress: () async {
                            if (found['subject'] == "free") return;

                            Get.defaultDialog(
                              title: "Mark Slot Free",
                              middleText:
                                  "Lab: $lab\nHours: ${hrs.join(', ')}\n\nMark entire slot as FREE?",
                              textConfirm: "Yes",
                              textCancel: "Cancel",
                              onConfirm: () async {
                                Get.back();

                                final dateStr =
                                    DateFormat('dd-MM-yyyy')
                                        .format(labController.selectedDate.value);

                                labController.formData.value = {
                                  "lab_name": lab,
                                  "hours_allotted": hrs.join(','),
                                  "subject_name": "free",
                                  "class_name": "free",
                                  "start_date": dateStr,
                                  "end_date": dateStr,
                                  "external": "external",
                                  "allot": "continue",
                                };

                                await labController.saveData(
                                  formKey: GlobalKey<FormState>(),
                                  startDateController:
                                      TextEditingController(text: dateStr),
                                  endDateController:
                                      TextEditingController(text: dateStr),
                                );
                              },
                            );
                          },
                          child: Container(
                            width: 60.0 * span,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(),
                              color: found['subject'] == "free"
                                  ? Colors.yellow[300]
                                  : found['external'] == "external"
                                      ? Colors.green[300]
                                      : Colors.blue[200],
                            ),
                            child: found['subject'] == "free"
                                ? const SizedBox()
                                : Text(
                                    "${found['class']} - ${found['subject']}",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
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

  // =====================================================
  //                  UI HELPERS
  // =====================================================
  Widget _headerCell(String text) {
    return Container(
      width: 60,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all()),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _cell(String text) {
    return Container(
      width: 60,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(border: Border.all()),
      child: Text(text),
    );
  }
}
