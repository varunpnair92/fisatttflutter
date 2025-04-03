import 'package:fisat_timetable/lab_allotment.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lab Allotment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LabAllotmentPage(),
    );
  }
}
