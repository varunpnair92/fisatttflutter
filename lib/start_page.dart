import 'package:fisat_timetable/start_control.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StartupPage extends StatelessWidget {
  final controller = Get.put(StartupController());

   StartupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()), // Show loading spinner
    );
  }
}
