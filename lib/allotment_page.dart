import 'package:flutter/material.dart';
import 'save_allotment_page.dart';
import 'show_allotment_page.dart';

class AllotmentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Allotments'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Save Allotment'),
              Tab(text: 'Show Allotment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SaveAllotmentPage(),
            ShowAllotmentPage(),
          ],
        ),
      ),
    );
  }
}
