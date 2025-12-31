import 'package:fisat_timetable/cummilativedata_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lab_controller.dart';
import 'shared.dart';

class CumulativePage extends StatefulWidget {
  final DateTime start;
  final DateTime end;

  const CumulativePage({
    super.key,
    required this.start,
    required this.end,
  });

  @override
  State<CumulativePage> createState() => _CumulativePageState();
}

class _CumulativePageState extends State<CumulativePage> {
  final LabController labController = Get.find();
  final Set<int> selected = {};

  List<CumulativeData> loaded = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("External Summary"),

        actions: [
          /// COPY BUTTON
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: selected.isEmpty ? null : copySelected,
          ),

          /// TELEGRAM BUTTON
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: selected.isEmpty ? null : sendTelegram,
          ),
        ],
      ),

      body: FutureBuilder(
        future: labController.fetchCumulative(widget.start, widget.end),
        builder: (context, AsyncSnapshot<List<CumulativeData>> snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          loaded = snap.data!;

          if (loaded.isEmpty) {
            return const Center(child: Text("No External Allotments Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: loaded.length,
            itemBuilder: (context, i) {
              final d = loaded[i];

              final isSelected = selected.contains(i);

              return Card(
                color: isSelected ? Colors.blue.shade50 : null,
                child: ListTile(
                  title: Text(
                    d.className,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "${d.subjectName}\n${d.dates}",
                    style: const TextStyle(height: 1.4),
                  ),
                  isThreeLine: true,

                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.blue)
                      : const Icon(Icons.circle_outlined),

                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selected.remove(i);
                      } else {
                        selected.add(i);
                      }
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// COPY SELECTED
  Future<void> copySelected() async {
    final buffer = StringBuffer();

    for (var index in selected) {
      final d = loaded[index];

      buffer.writeln(
          "Class: ${d.className}\n"
          "Subject: ${d.subjectName}\n"
          "Dates: ${d.dates}\n"
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.snackbar("Copied", "Selected items copied");
  }

  /// SEND TELEGRAM
  Future<void> sendTelegram() async {

    final buffer = StringBuffer();

    for (var index in selected) {
      final d = loaded[index];

      buffer.writeln(
          "\n"
          "🎓 Class: ${d.className}\n"
          "📘 Subject: ${d.subjectName}\n"
          "📅 Dates: ${d.dates}\n"
      );
    }

    final url = "${Sharedvariable().ip}/lab/send_message";

    final res = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": buffer.toString()}),
    );

    if (res.statusCode == 200) {
      Get.snackbar("Sent", "Message delivered to Telegram");
    } else {
      Get.snackbar("Failed", "Could not send message");
    }
  }
}
