import 'package:flutter/material.dart';
import 'save_allotment_page.dart';
import 'show_allotment_page.dart';

class AllotmentPage extends StatelessWidget {
  const AllotmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Allotments'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Save Allotment'),
              Tab(text: 'Show Allotment'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SaveAllotmentPage(),
            const ShowAllotmentPage(),
          ],
        ),
      ),
    );
  }
}
