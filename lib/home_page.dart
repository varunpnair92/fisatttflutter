import 'package:fisat_timetable/home_controller.dart';
import 'package:fisat_timetable/lab_allotment.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'allotment_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final pageIndex = Get.find<HomeController>().currentIndex.value;
        return IndexedStack(
          index: pageIndex,
          children: [
            LabAllotmentPage(),
            AllotmentPage(),
          ],
        );
      }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: Get.find<HomeController>().currentIndex.value,
        onTap: (index) {
          Get.find<HomeController>().currentIndex.value = index;
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Lab Allotment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Allotments',
          ),
        ],
      ),
    );
  }
}
