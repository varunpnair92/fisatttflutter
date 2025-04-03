import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class LabCalendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lab Calendar')),
      body: TableCalendar(
        firstDay: DateTime(2023, 1, 1), // Start of the calendar range
        lastDay: DateTime(2025, 12, 31), // End of the calendar range
        focusedDay: DateTime.now(),
        calendarFormat: CalendarFormat.month,
        onDaySelected: (selectedDay, focusedDay) {
          // Handle date selection
        },
        // Other properties and customizations
      ),
    );
  }
}
