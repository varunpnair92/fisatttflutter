import 'package:fisat_timetable/lab_external.dart';
import 'package:fisat_timetable/shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExamController extends GetxController {
  RxList<Labexternal> apiData = <Labexternal>[].obs;

  @override
  void onInit() {
    super.onInit();
    getData();
  }

  Future<void> getData() async {
    try {
      var data = await fetchLabExternal();
      if (data != null) {
        apiData.assignAll(data);
       // print("Data fetched and assigned successfully");
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

Future<List<Labexternal>?> fetchLabExternal() async {
  //print("called fetchLabExternal()");
  var url = "${Sharedvariable().ip}/lab/labexternal";
  try {
    final response = await http
        .get(Uri.parse(url), headers: {"Content-Type": "application/json"});

    if (response.statusCode == 200) {
      //print("Raw API Response: ${response.body}"); // ✅ Print raw JSON
      List jsonResponse = jsonDecode(response.body);
      //print("Parsed JSON: $jsonResponse");

      return jsonResponse.map((data) {
       // print("Processing: $data"); // ✅ Debugging each entry
        return Labexternal.fromJson(data);
      }).toList();
    } else {
      //print('Failed to load data. Status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    //print('Exception: $e');
    return null;
  }
}


Future<void> deleteAllotment(int id) async {
    try {
      final response = await http.delete(Uri.parse("${Sharedvariable().ip}/lab/delete_lab_allotment/$id/"));

      if (response.statusCode == 200) {
        apiData.removeWhere((allotment) => allotment.id == id);  // ✅ Auto-refresh UI
        apiData.refresh();
        Get.snackbar("Success", "Allotment deleted successfully",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Failed to delete allotment",
            snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      //print("Error deleting allotment: $e");
      Get.snackbar("Error", "Something went wrong",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

}
