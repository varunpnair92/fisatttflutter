import 'package:fisat_timetable/show_allotment_page_u.dart';
import 'package:flutter/material.dart';

class AllotmentPageU extends StatelessWidget {
  const AllotmentPageU({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Allotments'),
          bottom: const TabBar(
            tabs: [
              //Tab(text: 'Save Allotment'),
              Tab(text: 'Show Allotment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
           // SaveAllotmentPage(),
            ShowAllotmentPageU(),
          ],
        ),
      ),
    );
  }
}
