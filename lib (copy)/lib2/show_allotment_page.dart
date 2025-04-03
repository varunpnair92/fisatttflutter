import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'lab_controller.dart';

class ShowAllotmentPage extends StatelessWidget {
  final LabController labController = Get.find<LabController>();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        // Display saved allotments using labController
        return ListView(
          children: labController.labAllotments.entries.map((entry) {
            return ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value.toString()),
            );
          }).toList(),
        );
      }),
    );
  }
}
