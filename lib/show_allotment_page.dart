import 'package:fisat_timetable/api_controller.dart';
import 'package:fisat_timetable/shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:fisat_timetable/lab_external.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ShowAllotmentPage extends StatefulWidget {
  @override
  _ShowAllotmentPageState createState() => _ShowAllotmentPageState();
}

class _ShowAllotmentPageState extends State<ShowAllotmentPage> {
  final examController = Get.put(ExamController());

  DateTime selectedDate = DateTime.now(); // auto-load today's date
  bool isCheckBoxChecked = false;
  List<dynamic> freeLabSlots = [];

  // Selected IDs for multi-copy
  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    examController.fetchLabExternal(); // initial fetch
  }

  // ---------------------------
  // Fetch free lab slots for selectedDate
  // ---------------------------
  Future<void> fetchFreeLabSlots() async {
    String formattedDate = DateFormat('dd-MM-yyyy').format(selectedDate);
    String apiUrl = '${Sharedvariable().ip}/lab/labdata_free';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"date": formattedDate}),
      );

      if (response.statusCode == 200) {
        setState(() {
          freeLabSlots = jsonDecode(response.body)['free_slots'];
        });
      } else {
        print('Error fetching free lab slots: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching free lab slots: $e');
    }
  }

  // ---------------------------
  // Refresh / reload allotments
  // ---------------------------
  void refreshPage() async {
    await examController.fetchLabExternal();
    // Clear selection after refresh
    setState(() {
      selectedIds.clear();
    });
    Get.snackbar("Refreshed", "Allotments reloaded", snackPosition: SnackPosition.BOTTOM);
  }

  // ---------------------------
  // Copy single allotment to clipboard
  // ---------------------------
  void _copySingle(Labexternal a) {
    String text = """
Date: ${a.startDate}
Lab: ${a.labName}
Class: ${a.className}
Subject: ${a.subjectName}
Hours: ${a.hoursAllotted}
""";
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar("Copied", "Allotment copied to clipboard", snackPosition: SnackPosition.BOTTOM);
  }

  // ---------------------------
  // Copy selected allotments (multiple)
  // ---------------------------
  void _copySelected() {
    if (selectedIds.isEmpty) return;

    // Build combined text in the order of examController.apiData (sorted later by UI)
    List<Labexternal> dataList = examController.apiData;
    List<Labexternal> selected = dataList.where((a) => selectedIds.contains(a.id)).toList();

    if (selected.isEmpty) {
      Get.snackbar("No items", "Selected items are not available", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    String combined = selected.map((a) {
      return """
Date: ${a.startDate}
Lab: ${a.labName}
Class: ${a.className}
Subject: ${a.subjectName}
Hours: ${a.hoursAllotted}
""";
    }).join("\n-------------------------\n");

    Clipboard.setData(ClipboardData(text: combined.trim()));
    Get.snackbar("Copied", "${selected.length} allotments copied", snackPosition: SnackPosition.BOTTOM);

    // Optionally clear selection after copying:
    setState(() {
      selectedIds.clear();
    });
  }

  // ---------------------------
  // Delete dialog wrapper
  // ---------------------------
  void _showDeleteConfirmationDialog(int id) {
    Get.defaultDialog(
      title: "Delete Allotment",
      middleText: "Are you sure you want to delete this allotment?",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        examController.deleteAllotment(id);
        Get.back();
        // Refresh after delete to reflect changes
        refreshPage();
      },
    );
  }

  // ---------------------------
  // Sorting helper (date desc)
  // ---------------------------
  List<Labexternal> _sort(List<Labexternal> list) {
    try {
      list.sort((a, b) {
        DateTime da = DateFormat('dd-MM-yyyy').parse(a.startDate);
        DateTime db = DateFormat('dd-MM-yyyy').parse(b.startDate);
        return db.compareTo(da);
      });
    } catch (e) {
      // ignore parsing errors
    }
    return list;
  }

  // ---------------------------
  // Filter to match only date (ignore time)
  // ---------------------------
  List<Labexternal> _filterByDate(List<Labexternal> list) {
    return list.where((a) {
      try {
        DateTime d = DateFormat('dd-MM-yyyy').parse(a.startDate);
        return d.year == selectedDate.year && d.month == selectedDate.month && d.day == selectedDate.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lab Allotments"),
        actions: [
          // Refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: "Reload Allotments",
            onPressed: refreshPage,
          ),

          // Date picker
          IconButton(
            icon: Icon(Icons.calendar_today),
            tooltip: "Pick Date",
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2099),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
                if (isCheckBoxChecked) fetchFreeLabSlots();
              }
            },
          ),

          // Free slots toggle
          Row(
            children: [
              Text("Show Free Slots"),
              Checkbox(
                value: isCheckBoxChecked,
                onChanged: (v) {
                  setState(() {
                    isCheckBoxChecked = v ?? false;
                    if (isCheckBoxChecked)
                      fetchFreeLabSlots();
                    else
                      freeLabSlots.clear();
                  });
                },
              ),
            ],
          ),
        ],
      ),

      // Body chooses between free slots view or allotments view
      body: isCheckBoxChecked ? _buildFreeLabSlotsView() : _buildAllotmentsView(),

      // Floating button - appears only when there are selected items
      floatingActionButton: selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              icon: Icon(Icons.copy),
              label: Text("Copy Selected (${selectedIds.length})"),
              onPressed: _copySelected,
            )
          : null,
    );
  }

  // ---------------------------
  // Free slots view
  // ---------------------------
  Widget _buildFreeLabSlotsView() {
    if (freeLabSlots.isEmpty) {
      return Center(child: Text("No free lab slots available"));
    }

    return ListView.builder(
      itemCount: freeLabSlots.length,
      itemBuilder: (context, index) {
        final slot = freeLabSlots[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: ListTile(
            title: Text("Lab: ${slot['lab_name']}"),
            subtitle: Text("Free Hours: ${slot['hours_free']}"),
          ),
        );
      },
    );
  }

  // ---------------------------
  // Allotments view with checkboxes, copy, delete
  // ---------------------------
  Widget _buildAllotmentsView() {
    return Obx(() {
      if (examController.apiData.isEmpty) {
        return Center(child: Text("No allotments available"));
      }

      // Work on a local list copy
      List<Labexternal> dataList = List<Labexternal>.from(examController.apiData);
      List<Labexternal> sorted = _sort(dataList);
      List<Labexternal> filtered = _filterByDate(sorted);

      if (filtered.isEmpty) {
        return Center(child: Text("No allotments for selected date"));
      }

      return ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final allot = filtered[index];

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            color: selectedIds.contains(allot.id) ? Colors.blue.shade50 : null,
            child: ListTile(
              contentPadding: EdgeInsets.all(16),

              // Left checkbox for multi-select
              leading: Checkbox(
                value: selectedIds.contains(allot.id),
                onChanged: (bool? val) {
                  setState(() {
                    if (val == true)
                      selectedIds.add(allot.id);
                    else
                      selectedIds.remove(allot.id);
                  });
                },
              ),

              title: Text("Date: ${allot.startDate}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Lab: ${allot.labName}"),
                  Text("Class: ${allot.className}"),
                  Text("Subject: ${allot.subjectName}"),
                  Text("Hours: ${allot.hoursAllotted}"),
                ],
              ),

              // Trailing icons: single copy + delete
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Single copy icon
                  IconButton(
                    icon: Icon(Icons.copy, color: Colors.blue),
                    onPressed: () => _copySingle(allot),
                  ),

                  // Delete icon
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmationDialog(allot.id),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}
