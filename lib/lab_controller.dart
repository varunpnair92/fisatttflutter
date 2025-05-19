import 'package:fisat_timetable/shared.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'lab_external.dart'; // Import your Labexternal model

class LabController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var calendarFormat = CalendarFormat.month.obs;
  var labAllotments = <String, List<Map<String, dynamic>>>{}.obs;
  var labAllotments2 = <Labexternal>[].obs;
  var labAllotmentsR = <String, List<Map<String, dynamic>>>{}.obs;

  var formData = <String, String>{
    "lab_name": "",
    "hours_allotted": "",
    "subject_name": "",
    "class_name": "",
    "start_date": "",
    "end_date": "",
    "allot": "continue",
    "external": "external",
  }.obs;

  @override
  void onInit() {
    super.onInit();
    getLabExternal();
    // Fetch initial data
  }

  // Method to handle date selection from the calendar
  void selectDate(DateTime date) {
    selectedDate.value = date;
    fetchLabAllotmentsForDate(date);
  }

  // Method to update the selected date
  void updateDate(DateTime newDate) {
    selectedDate.value = newDate;
    fetchLabAllotmentsForDate(newDate);
  }

  // Method to change the calendar view format (month, week, etc.)
  void changeCalendarFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

  // Fetch lab allotments data for the selected date
  Future<void> fetchLabAllotmentsForDate(DateTime date) async {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    var url = "${Sharedvariable().ip}/lab/labdata";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": formattedDate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        //print("Date${response.body}");
        labAllotments.value = Map<String, List<Map<String, dynamic>>>.from(
          data.map((key, value) => MapEntry(
                key,
                List<Map<String, dynamic>>.from(value),
              )),
        );
      } else {
        //print("Error: ${response.statusCode}");
        //print("Response body: ${response.body}");
      }
    } catch (e) {
      //print("Exception: $e");
    }
  }

  // Get lab entries for a specific date
  List<Map<String, dynamic>> getLabEntriesForDate(DateTime date) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return labAllotments.entries
        .expand((entry) =>
            entry.value.where((e) => e['start_date'] == formattedDate))
        .toList();
  }

  // Save form data to the server
  Future<void> saveData() async {
    var url =
        "${Sharedvariable().ip}/lab/laballot"; // URL for the normal request
    var continueUrl =
        "${Sharedvariable().ip}/lab/laballot_continue"; // URL for continuing without conflict check

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData.value),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Allotment successfully saved
        Get.snackbar("Saved", "Allotment Saved");
        getLabExternal();
        update();
      } else if (response.statusCode == 400) {
        // Conflict detected, show dialog with the conflict message
        final responseBody = jsonDecode(response.body);
        final conflictMessage = responseBody["error"] ?? "Unknown conflict";

        // Show dialog with conflict message
        Get.defaultDialog(
          title: "Conflict Detected",
          middleText: conflictMessage,
          textCancel: "Cancel",
          textConfirm: "Continue",
          barrierDismissible: false, // Prevent accidental dismissals
          onCancel: () {
            Get.back(); // Ensure dialog is dismissed
            Future.delayed(Duration(milliseconds: 100), () {
              Get.snackbar("Cancelled", "Allotment process cancelled");
            });
          },
          onConfirm: () async {
            Get.back(); // Close the dialog before proceeding

            formData.value["allot"] =
                "continue"; // Set allot flag to 'continue'

            try {
              // Send request to continue saving
              final continueResponse = await http.post(
                Uri.parse(continueUrl),
                headers: {"Content-Type": "application/json"},
                body: jsonEncode(formData.value),
              );

              if (continueResponse.statusCode == 200 ||
                  continueResponse.statusCode == 201) {
                getLabExternal();
                update();
                Get.snackbar("Saved", "Allotment Saved with Conflict");
              } else {
                Get.snackbar("Error", "Failed to save data with conflict.");
              }
            } catch (e) {
              Get.snackbar("Error", "Exception while saving data: $e");
            }
          },
        );
      } else {
        Get.snackbar("Error", "Failed to save data.");
      }
    } catch (e) {
      Get.snackbar("Error", "Exception while saving data: $e");
    }
  }

  Future<List<Labexternal>?> getLabExternal() async {
    var url2 = "${Sharedvariable().ip}/lab/labexternal";
    var response = await http
        .get(Uri.parse(url2), headers: {"Content-Type": "application/json"});

    String receivedJson = response.body;

    if (response.statusCode == 200) {
      var data = await json.decode(response.body);
      //print(data);

      List bodyjosn = jsonDecode(response.body);
      return bodyjosn.map((e) => Labexternal.fromJson(e)).toList();
    } else {
      return null;
    }
  }

  Future<void> fetchLabAllotmentsForRange(
      DateTime startDate, DateTime endDate) async {
    final formattedStartDate = DateFormat('dd-MM-yyyy').format(startDate);
    final formattedEndDate = DateFormat('dd-MM-yyyy').format(endDate);

    var url =
        "${Sharedvariable().ip}/lab/labdata_range"; // Ensure API supports date range

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"start_date": formattedStartDate, "end_date": formattedEndDate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        labAllotmentsR.value = Map<String, List<Map<String, dynamic>>>.from(
          data.map((key, value) => MapEntry(
                key,
                List<Map<String, dynamic>>.from(value),
              )),
        );
      } else {
        // print("Error: ${response.statusCode}");
        // print("Response body: ${response.body}");
      }
    } catch (e) {
      // print("Exception: $e");
    }
  }
}
