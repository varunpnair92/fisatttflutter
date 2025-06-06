import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';

class LabController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var calendarFormat = CalendarFormat.month.obs;
  var labAllotments = <String, List<Map<String, dynamic>>>{}.obs;

  void selectDate(DateTime date) {
    selectedDate.value = date;
    fetchLabAllotmentsForDate(date);
  }

  void changeCalendarFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

  Future<void> fetchLabAllotmentsForDate(DateTime date) async {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    final url = 'http://144.24.153.172:4455/lab/labdata';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": formattedDate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Ensure the fetched data has the correct structure
        labAllotments.value = Map<String, List<Map<String, dynamic>>>.from(
          data.map((key, value) => MapEntry(
            key,
            List<Map<String, dynamic>>.from(value),
          )),
        );
      } else {
       // print("Error: ${response.statusCode}");
        //print("Response body: ${response.body}");
      }
    } catch (e) {
      //print("Exception: $e");
    }
  }

  List<Map<String, dynamic>> getLabEntriesForDate(DateTime date) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return labAllotments.entries
        .expand((entry) => entry.value.where((e) => e['start_date'] == formattedDate))
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }
}