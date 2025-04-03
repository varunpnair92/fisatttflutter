import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'lab_controller.dart';

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
              lastDay: DateTime.utc(2025, 12, 31),
              focusedDay: labController.selectedDate.value,
              calendarFormat: labController.calendarFormat.value,
              selectedDayPredicate: (day) {
                return isSameDay(labController.selectedDate.value, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                labController.selectDate(selectedDay);
              },
              onFormatChanged: (format) {
                labController.changeCalendarFormat(format);
              },
              onPageChanged: (focusedDay) {
                labController.updateDate(
                    focusedDay); // Ensures the selected date is updated
              },
            );
          }),
          Expanded(
            child: Obx(() {
              final selectedDate = labController.selectedDate.value;
              return _buildAllotmentTable(selectedDate);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAllotmentTable(DateTime selectedDate) {
    final labAllotments = labController.labAllotments;
    final dayAllotments =
        labAllotments[DateFormat('dd-MM-yyyy').format(selectedDate)] ?? [];

    return ListView(
      children: <Widget>[
        _buildTableHeader(),
        ...dayAllotments.map((allotment) {
          return _buildTableRow(allotment);
        }).toList(),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: [
            _buildMergedCell('Subject', 2),
            _buildMergedCell('Class', 2),
            _buildMergedCell('Hours', 1),
          ],
        ),
      ],
    );
  }

  Widget _buildTableRow(Map<String, dynamic> allotment) {
    return Table(
      border: TableBorder.all(),
      children: [
        TableRow(
          children: [
            _buildCell(allotment['subject'] ?? ''),
            _buildCell(allotment['class'] ?? ''),
            _buildCell(allotment['hours'] ?? ''),
          ],
        ),
      ],
    );
  }

  Widget _buildCell(String content) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(content, textAlign: TextAlign.center),
    );
  }

  Widget _buildMergedCell(String content, int colspan) {
    return TableCell(
      child: Center(
        child: Text(
          content,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      verticalAlignment: TableCellVerticalAlignment.middle,
    );
  }

  Widget _buildEmptyCell() {
    return TableCell(
      child: Container(
        height: 40,
        color: Colors.grey[200],
      ),
    );
  }
}
