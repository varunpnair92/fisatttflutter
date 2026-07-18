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
    const url = 'http://144.24.153.172:4455/lab/labdata';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": formattedDate}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        labAllotments.value = Map<String, List<Map<String, dynamic>>>.from(
          data.map((key, value) => MapEntry(
                key,
                List<Map<String, dynamic>>.from(value),
              )),
        );
      } else {
        print("Error: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
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
    const url =
        'http://144.24.153.172:4455/lab/laballot'; // URL for the normal request
    const continueUrl =
        'http://144.24.153.172:4455/lab/laballot_continue'; // URL for continuing without conflict check

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData.value),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully saved the allotment
        Get.snackbar("Saved", "Allotment Saved");
      } else if (response.statusCode == 400) {
        // Conflict detected (status 409), show dialog with the conflict message
        final responseBody = jsonDecode(response.body);
        final conflictMessage = responseBody["error"] ?? "Unknown conflict";

        // Check if the message indicates a conflict
        if (conflictMessage.contains("Conflict detected")) {
          // Show dialog with "Continue" option
          Get.defaultDialog(
              title: "Conflict Detected",
              middleText: conflictMessage, // Show the conflict message
              textCancel: "Cancel",
              textConfirm: "Continue",
              onConfirm: () async {
                // User chooses to continue despite conflict
                formData.value["allot"] =
                    "continue"; // Set allot flag to 'continue'

                // Send request to continue saving (skip conflict check)
                final continueResponse = await http.post(
                  Uri.parse(continueUrl),
                  headers: {"Content-Type": "application/json"},
                  body: jsonEncode(formData.value),
                );

                if (continueResponse.statusCode == 200 ||
                    continueResponse.statusCode == 201) {
                  // Successfully saved with conflict
                  Get.snackbar("Saved", "Allotment Saved with Conflict");
                } else {
                  // Log the response body for debugging
                  print("Error: ${continueResponse.body}");
                  Get.snackbar("Error", "Failed to save data with conflict.");
                }
                Get.back(); // Close dialog
              },
              onCancel: () {
                // User cancels the operation
                Get.snackbar("Cancelled", "Allotment not saved.");
              });
        } else {
          // If the error is not a conflict, display it as an error message
          Get.snackbar(
              "Error", "Conflict not handled properly: $conflictMessage");
        }
      } else {
        // For other errors, display the message
        print("Error: ${response.body}"); // Log the response body for debugging
        Get.snackbar("Error", "Failed to save data.");
      }
    } catch (e) {
      // Catch any exceptions during the HTTP request
      Get.snackbar("Error", "Exception while saving data: $e");
    }
  }

  Future<List<Labexternal>?> getLabExternal() async {
    const url2 = 'http://144.24.153.172:4455/lab/labexternal';
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
}
