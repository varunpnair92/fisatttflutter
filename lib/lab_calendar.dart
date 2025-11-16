import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class LabCalendar extends StatefulWidget {
  @override
  _LabCalendarState createState() => _LabCalendarState();
}

class _LabCalendarState extends State<LabCalendar> {
  // Set our date range (whole year 2025)
  final DateTime firstDay = DateTime(2025, 1, 1);
  final DateTime lastDay = DateTime(2095, 12, 31);

  // Initialize focusedDay to today, but clamped to our range
  late DateTime focusedDay = _clampDate(DateTime.now());

  DateTime? selectedDay;

  // Helper function to clamp any date to our valid range
  DateTime _clampDate(DateTime date) {
    // First remove time portion (set to midnight)
    final normalized = DateTime(date.year, date.month, date.day);
    
    // Then clamp to our range
    if (normalized.isBefore(firstDay)) return firstDay;
    if (normalized.isAfter(lastDay)) return lastDay;
    return normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Lab Calendar')),
      body: TableCalendar(
  firstDay: DateTime(2025, 1, 1), 
  lastDay: DateTime(2025, 12, 31), 
  focusedDay: DateTime.now().isBefore(DateTime(2025, 1, 1)) 
      ? DateTime(2025, 1, 1)
      : (DateTime.now().isAfter(DateTime(2025, 12, 31))
          ? DateTime(2025, 12, 31)
          : DateTime.now()), 
  calendarFormat: CalendarFormat.month,
  onDaySelected: (selectedDay, focusedDay) {
    // Ensure focusedDay is updated within bounds
    setState(() {
      focusedDay = selectedDay.isAfter(DateTime(2025, 12, 31))
          ? DateTime(2025, 12, 31)
          : selectedDay;
    });
  },
)
,
    );
  }
}