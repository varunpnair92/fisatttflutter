import 'package:fisat_timetable/cummilativedata_model.dart';
import 'package:fisat_timetable/shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'lab_external.dart';

class LabController extends GetxController {
  var selectedDate = DateTime.now().obs;
  var calendarFormat = CalendarFormat.month.obs;
  var labAllotments = <String, List<Map<String, dynamic>>>{}.obs;
  var labAllotments2 = <Labexternal>[].obs;
  var labAllotmentsR = <String, List<Map<String, dynamic>>>{}.obs;
  var apiData = <Labexternal>[].obs;
  var pdfFilter = 'both'.obs;
  var selectedLabs = <String>[].obs;
  

  // ✅ allot is NOT set here → only controlled by UI
  var formData = <String, dynamic>{
    "lab_name": "",
    "lab_names": <String>[],
    "hours_allotted": "",
    "subject_name": "",
    "class_name": "",
    "start_date": "",
    "end_date": "",
    "external": "external",
  }.obs;

  @override
  void onInit() {
    super.onInit();
    getLabExternal();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    fetchLabAllotmentsForDate(date);
  }

  void updateDate(DateTime newDate) {
    selectedDate.value = newDate;
    fetchLabAllotmentsForDate(newDate);
  }

  void changeCalendarFormat(CalendarFormat format) {
    calendarFormat.value = format;
  }

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
        labAllotments.value = Map<String, List<Map<String, dynamic>>>.from(
          data.map((key, value) =>
              MapEntry(key, List<Map<String, dynamic>>.from(value))),
        );
      }
    } catch (e) {}
  }

  List<Map<String, dynamic>> getLabEntriesForDate(DateTime date) {
    final formattedDate = DateFormat('dd-MM-yyyy').format(date);
    return labAllotments.entries
        .expand((entry) =>
            entry.value.where((e) => e['start_date'] == formattedDate))
        .toList();
  }

  // Future<void> saveData({
  //   required GlobalKey<FormState> formKey,
  //   required TextEditingController startDateController,
  //   required TextEditingController endDateController,
  // }) async {
  //   // ✅ Ensure radio button was selected
  //   if (!formData.containsKey("allot")) {
  //     Get.snackbar("Error", "Please select Continue or Repeat");
  //     return;
  //   }

  //   var url = "${Sharedvariable().ip}/lab/laballot";
  //   var continueUrl = "${Sharedvariable().ip}/lab/laballot_continue";

  //   try {
  //     final response = await http.post(
  //       Uri.parse(url),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode(formData.value),
  //     );

  //     if (response.statusCode == 200 || response.statusCode == 201) {
  //       Get.snackbar("Saved", "Allotment Saved");
  //       getLabExternal();
  //       clearAll(formKey: formKey, startDateController: startDateController, endDateController: endDateController);
  //     }

  //     else if (response.statusCode == 400) {
  //       final responseBody = jsonDecode(response.body);
  //       final conflictMessage = responseBody["error"] ?? "Unknown conflict";

  //       Get.defaultDialog(
  //         title: "Conflict Detected",
  //         middleText: conflictMessage,
  //         textCancel: "Cancel",
  //         textConfirm: "Continue",
  //         barrierDismissible: false,
  //         onCancel: () {
  //           Get.back();
  //           Get.snackbar("Cancelled", "Allotment process cancelled");
  //           clearAll(formKey: formKey, startDateController: startDateController, endDateController: endDateController);
  //         },
  //         onConfirm: () async {
  //           Get.back();

  //           formData["allot"] = "continue";

  //           try {
  //             final continueResponse = await http.post(
  //               Uri.parse(continueUrl),
  //               headers: {"Content-Type": "application/json"},
  //               body: jsonEncode(formData.value),
  //             );

  //             if (continueResponse.statusCode == 200 ||
  //                 continueResponse.statusCode == 201) {
  //               getLabExternal();
  //               Get.snackbar("Saved", "Allotment Saved with Conflict");
  //               clearAll(formKey: formKey, startDateController: startDateController, endDateController: endDateController);
  //             } else {
  //               Get.snackbar("Error", "Failed to save data with conflict.");
  //             }
  //           } catch (e) {
  //             Get.snackbar("Error", "Exception while saving data: $e");
  //           }
  //         },
  //       );
  //     }

  //     else {
  //       Get.snackbar("Error", "Failed to save data.");
  //     }
  //   } catch (e) {
  //     Get.snackbar("Error", "Exception while saving data: $e");
  //   }
  // }

  Future<void> saveData({
    required GlobalKey<FormState> formKey,
    required TextEditingController startDateController,
    required TextEditingController endDateController,
  }) async {
    if (!formData.containsKey("allot")) {
      Get.snackbar("Error", "Please select Continue or Repeat");
      return;
    }

    // =====================================================
    // 🆕 MULTI-LAB FLOW (ONLY WHEN >1 LAB SELECTED)
    // =====================================================
    if (selectedLabs.length > 1) {
      final conflictUrl = "${Sharedvariable().ip}/lab/multi-lab-conflicts/";
      final saveMultiUrl = "${Sharedvariable().ip}/lab/multi-lab-allotment/";

      final conflictBody = {
        "lab_names": selectedLabs.toList(),
        "hours_allotted": formData["hours_allotted"],
        "start_date": formData["start_date"],
        "end_date": formData["end_date"],
      };

      try {
        final conflictRes = await http.post(
          Uri.parse(conflictUrl),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(conflictBody),
        );

        // ✅ NO CONFLICT
        if (conflictRes.statusCode == 200) {
          //formData["lab_names"] = jsonEncode(selectedLabs.toList());
          formData["lab_names"] = selectedLabs.toList();


          final saveRes = await http.post(
            Uri.parse(saveMultiUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(formData.value),
          );

          if (saveRes.statusCode == 200 || saveRes.statusCode == 201) {
            Get.snackbar("Saved", "Allotment Saved");
            getLabExternal();
            clearAll(
              formKey: formKey,
              startDateController: startDateController,
              endDateController: endDateController,
            );
          }
          return;
        }

        // ⚠ CONFLICT FOUND
        final conflicts = jsonDecode(conflictRes.body)["conflicts"];

        Get.defaultDialog(
          title: "Conflicts Found",
          middleText: conflicts
              .map((c) => "${c['lab']} → ${c['date']} → Hours ${c['hours']}")
              .join("\n"),
          textCancel: "Cancel",
          textConfirm: "Continue",
          onConfirm: () async {
            Get.back();
            //formData["lab_names"] = jsonEncode(selectedLabs.toList());
            formData["lab_names"] = selectedLabs.toList();

            formData["allot"] = "continue";

            final forceSaveRes = await http.post(
              Uri.parse(saveMultiUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(formData.value),
            );

            if (forceSaveRes.statusCode == 200 ||
                forceSaveRes.statusCode == 201) {
              Get.snackbar("Saved", "Allotment Saved with Conflict");
              getLabExternal();
              clearAll(
                formKey: formKey,
                startDateController: startDateController,
                endDateController: endDateController,
              );
            }
          },
        );
      } catch (e) {
        Get.snackbar("Error", "Exception: $e");
        
      }

      return; // stop here for multi-lab
    }

    // =====================================================
    // 🔵 ORIGINAL SINGLE LAB LOGIC (UNCHANGED)
    // =====================================================

    var url = "${Sharedvariable().ip}/lab/laballot";
    var continueUrl = "${Sharedvariable().ip}/lab/laballot_continue";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(formData.value),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar("Saved", "Allotment Saved");
        getLabExternal();
        clearAll(
          formKey: formKey,
          startDateController: startDateController,
          endDateController: endDateController,
        );
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        final conflictMessage = responseBody["error"] ?? "Unknown conflict";

        Get.defaultDialog(
          title: "Conflict Detected",
          middleText: conflictMessage,
          textCancel: "Cancel",
          textConfirm: "Continue",
          barrierDismissible: false,
          onCancel: () {
            Get.back();
            Get.snackbar("Cancelled", "Allotment process cancelled");
            clearAll(
              formKey: formKey,
              startDateController: startDateController,
              endDateController: endDateController,
            );
          },
          onConfirm: () async {
            Get.back();
            formData["allot"] = "continue";

            final continueResponse = await http.post(
              Uri.parse(continueUrl),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode(formData.value),
            );

            if (continueResponse.statusCode == 200 ||
                continueResponse.statusCode == 201) {
              getLabExternal();
              Get.snackbar("Saved", "Allotment Saved with Conflict");
              clearAll(
                formKey: formKey,
                startDateController: startDateController,
                endDateController: endDateController,
              );
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

    if (response.statusCode == 200) {
      List bodyjson = jsonDecode(response.body);
      return bodyjson.map((e) => Labexternal.fromJson(e)).toList();
    }
    return null;
  }

  Future<void> fetchLabAllotmentsForRange(
      DateTime startDate, DateTime endDate) async {
    final formattedStart = DateFormat('dd-MM-yyyy').format(startDate);
    final formattedEnd = DateFormat('dd-MM-yyyy').format(endDate);

    var url = "${Sharedvariable().ip}/lab/labdata_range";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"start_date": formattedStart, "end_date": formattedEnd}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        labAllotmentsR.value = Map<String, List<Map<String, dynamic>>>.from(
          data.map((key, value) =>
              MapEntry(key, List<Map<String, dynamic>>.from(value))),
        );
      }
    } catch (e) {}
  }

  void clearAll({
    GlobalKey<FormState>? formKey,
    TextEditingController? startDateController,
    TextEditingController? endDateController,
  }) {
    // ❌ DO NOT SET "allot" — UI will control it
    formData.value = {
      "lab_name": "",
      "hours_allotted": "",
      "subject_name": "",
      "class_name": "",
      "start_date": "",
      "end_date": "",
      "external": "external",
    };

    formKey?.currentState?.reset();
    startDateController?.clear();
    endDateController?.clear();
    update();
  }

//get cummilative data within a date range
  Future<List<CumulativeData>> fetchCumulative(
      DateTime start, DateTime end) async {
    final s = DateFormat("dd-MM-yyyy").format(start);
    final e = DateFormat("dd-MM-yyyy").format(end);

    final url =
        "${Sharedvariable().ip}/lab/cumulative_external_range?start_date=$s&end_date=$e";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as List;
      return body.map((e) => CumulativeData.fromJson(e)).toList();
    }

    return [];
  }

//free slot range
  Future<Map<String, dynamic>> fetchFreeSlotsRange(
      DateTime start, DateTime end) async {
    final s = DateFormat("dd-MM-yyyy").format(start);
    final e = DateFormat("dd-MM-yyyy").format(end);

    final url = "${Sharedvariable().ip}/lab/lab_free_slots_range";

    try {
      final res = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "start_date": s,
          "end_date": e,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (e) {
      // print("Error fetching free slots: $e");
    }

    return {"data": []};
  }
}
