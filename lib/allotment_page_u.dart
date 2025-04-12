import 'package:flutter/material.dart';
import 'show_allotment_page.dart';

class AllotmentPageU extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Allotments'),
          bottom: TabBar(
            tabs: [
              //Tab(text: 'Save Allotment'),
              Tab(text: 'Show Allotment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
           // SaveAllotmentPage(),
            ShowAllotmentPage(),
          ],
        ),
      ),
    );
  }
}
