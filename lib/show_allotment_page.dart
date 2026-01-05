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
  const ShowAllotmentPage({super.key});

  @override
  _ShowAllotmentPageState createState() => _ShowAllotmentPageState();
}

class _ShowAllotmentPageState extends State<ShowAllotmentPage> {
  final examController = Get.put(ExamController());

  DateTime selectedDate = DateTime.now();
  bool isCheckBoxChecked = false;
  List<dynamic> freeLabSlots = [];

  Set<int> selectedIds = {};

  @override
  void initState() {
    super.initState();
    examController.getData(); // Fetch initial data
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
        // print('Error fetching free lab slots: ${response.statusCode}');
      }
    } catch (e) {
      // print('Error fetching free lab slots: $e');
    }
  }

  // ---------------------------
  // Refresh page
  // ---------------------------
  void refreshPage() async {
    await examController.getData();
    setState(() {
      selectedIds.clear();
    });
    Get.snackbar("Refreshed", "Allotments reloaded",
        snackPosition: SnackPosition.BOTTOM);
  }

  // ---------------------------
  // Copy single allotment
  // ---------------------------
  void _copySingle(Labexternal a) {
    String hours = a.hoursAllotted
        .split(',')
        .map((h) => h.trim() == '8' ? 'LB' : h.trim())
        .join(', ');

    String text = """
Date: ${a.startDate}
Lab: ${a.labName}
Class: ${a.className}
Subject: ${a.subjectName}
Hours: $hours
""";

    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar("Copied", "Allotment copied",
        snackPosition: SnackPosition.BOTTOM);
  }

  // ---------------------------
  // Copy selected allotments
  // ---------------------------
  void _copySelected() {
    if (selectedIds.isEmpty) return;

    List<Labexternal> selected = examController.apiData
        .where((a) => selectedIds.contains(a.id))
        .toList();

    String combined = selected.map((a) {
      String hours = a.hoursAllotted
          .split(',')
          .map((h) => h.trim() == '8' ? 'LB' : h.trim())
          .join(', ');

      return """
Date: ${a.startDate}
Lab: ${a.labName}
Class: ${a.className}
Subject: ${a.subjectName}
Hours: $hours
""";
    }).join("\n-------------------------\n");

    Clipboard.setData(ClipboardData(text: combined.trim()));
    Get.snackbar("Copied", "${selected.length} items copied",
        snackPosition: SnackPosition.BOTTOM);

    setState(() {
      selectedIds.clear();
    });
  }

  // ---------------------------
  // Delete
  // ---------------------------
  void _showDeleteConfirmationDialog(Labexternal a) {
    Get.defaultDialog(
      title: "Delete Allotment",
      middleText: "Are you sure?",
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        // -------- DELETE --------
        await examController.deleteAllotment(a.id);

        // -------- FORMAT HOURS --------
        String hours = a.hoursAllotted
            .split(',')
            .map((h) => h.trim() == '8' ? 'LB' : h.trim())
            .join(', ');

        // -------- TELEGRAM MESSAGE --------
        String message = """
🔴 <b>Allotment Cancelled</b>

📅 Date: ${a.startDate}
🧪 Lab: ${a.labName}
🎓 Class: ${a.className}
📘 Subject: ${a.subjectName}
⏰ Hours: $hours
""";

        await http.post(
          Uri.parse("${Sharedvariable().ip}/lab/send_message"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"message": message}),
        );

        Get.back();
        refreshPage();
      },
    );
  }

  // ---------------------------
  // Sorting helper (descending by date)
  // ---------------------------
  List<Labexternal> _sort(List<Labexternal> list) {
    try {
      list.sort((a, b) {
        DateTime da = DateFormat('dd-MM-yyyy').parse(a.startDate);
        DateTime db = DateFormat('dd-MM-yyyy').parse(b.startDate);
        return db.compareTo(da);
      });
    } catch (_) {}
    return list;
  }

  // ---------------------------
  // Filter by selected date
  // ---------------------------
  List<Labexternal> _filterByDate(List<Labexternal> list) {
    return list.where((a) {
      try {
        DateTime d = DateFormat('dd-MM-yyyy').parse(a.startDate);
        return d.year == selectedDate.year &&
            d.month == selectedDate.month &&
            d.day == selectedDate.day;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ========================================================================
  // UI
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lab Allotments"),
        actions: [
          // 🔄 Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reload",
            onPressed: refreshPage,
          ),

          // 📅 Date picker
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: "Pick Date",
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime(2099),
              );
              if (picked != null) {
                setState(() => selectedDate = picked);
                if (isCheckBoxChecked) fetchFreeLabSlots();
              }
            },
          ),

          // 🟩 SHOW FREE SLOTS TOGGLE (RESTORED)
          Row(
            children: [
              const Text("Show Free Slots"),
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
      body:
          isCheckBoxChecked ? _buildFreeLabSlotsView() : _buildAllotmentsView(),
      floatingActionButton: selectedIds.isNotEmpty
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.copy),
              label: Text("Copy (${selectedIds.length})"),
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
      return const Center(child: Text("No free lab slots"));
    }

    return ListView.builder(
      itemCount: freeLabSlots.length,
      itemBuilder: (_, index) {
        final slot = freeLabSlots[index];
        return Card(
          child: ListTile(
            title: Text("Lab: ${slot['lab_name']}"),
            subtitle: Text("Free Hours: ${slot['hours_free']}"),
          ),
        );
      },
    );
  }

  // ---------------------------
  // Allotments list view (Reactive)
  // ---------------------------
  Widget _buildAllotmentsView() {
    return Obx(() {
      if (examController.apiData.isEmpty) {
        return const Center(child: Text("No allotments available"));
      }

      List<Labexternal> sorted =
          _sort(List<Labexternal>.from(examController.apiData));
      List<Labexternal> filtered = _filterByDate(sorted);

      if (filtered.isEmpty) {
        return const Center(child: Text("No allotments for this date"));
      }

      return ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (_, index) {
          final allot = filtered[index];

          return Card(
            margin: const EdgeInsets.all(8),
            color: selectedIds.contains(allot.id) ? Colors.blue.shade50 : null,
            child: ListTile(
              leading: Checkbox(
                value: selectedIds.contains(allot.id),
                onChanged: (v) {
                  setState(() {
                    if (v == true)
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
                  Text(
                      "Hours: ${allot.hoursAllotted.split(',').map((h) => h.trim() == '8' ? 'LB' : h.trim()).join(',')}"),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteConfirmationDialog(allot),
              ),
            ),
          );
        },
      );
    });
  }
}
