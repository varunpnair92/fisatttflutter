import 'package:fisat_timetable/cummilativedata_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import 'lab_controller.dart';

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

  /// store selected index values
  final Set<int> selected = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("External Summary"),

        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: selected.isEmpty ? null : copySelected,
          ),
        ],
      ),

      body: FutureBuilder(
        future: labController.fetchCumulative(widget.start, widget.end),
        builder: (context, AsyncSnapshot<List<CumulativeData>> snap) {

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snap.data!;

          if (list.isEmpty) {
            return const Center(child: Text("No External Allotments Found"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final d = list[i];

              final txt =
                  "Class: ${d.className}\n"
                  "Subject: ${d.subjectName}\n"
                  "Dates: ${d.dates}";

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

                  onLongPress: () async {
                    await Clipboard.setData(ClipboardData(text: txt));
                    Get.snackbar("Copied", "Item copied");
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> copySelected() async {
    final data = await labController.fetchCumulative(widget.start, widget.end);

    final buffer = StringBuffer();

    for (var index in selected) {
      final d = data[index];
      buffer.writeln(
          "Class: ${d.className}\n"
          "Subject: ${d.subjectName}\n"
          "Dates: ${d.dates}\n"
      );
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));

    Get.snackbar("Copied", "Selected items copied");
  }
}
