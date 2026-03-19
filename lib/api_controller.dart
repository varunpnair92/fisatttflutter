import 'package:fisat_timetable/lab_external.dart';
import 'package:fisat_timetable/shared.dart';
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

  Future<bool> deleteAllotment(int id) async {
    try {
      final response = await http.delete(
          Uri.parse("${Sharedvariable().ip}/lab/delete_lab_allotment/$id/"));

      if (response.statusCode == 200) {
        apiData.removeWhere((allotment) => allotment.id == id);
        apiData.refresh();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
