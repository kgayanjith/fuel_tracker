import 'package:flutter/material.dart';
import 'package:fuel_tracker/screens/report_preview_screen.dart';
import 'package:fuel_tracker/widgets/appbar.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ReportsList extends StatefulWidget {
  const ReportsList({super.key});

  @override
  State<ReportsList> createState() => _ReportsListState();
}

class _ReportsListState extends State<ReportsList> {
  final List<Map<String, dynamic>> generators = [
    const {
      "id": "1",
      "name": "Civil Department",
      "location": "Civil",
      "model": "CAT-18KS",
      "liters": "10",
      "image": "assets/generator1.png",
      "capacity": "50",
      "usage": "10",
    },
    const {
      "id": "2",
      "name": "Main Hall",
      "location": "Main",
      "model": "CAT-19KS",
      "liters": "5",
      "image": "assets/generator2.jpg",
      "capacity": "35",
      "usage": "7",
    },
    const {
      "id": "3",
      "name": "PC Lab",
      "location": "Lab 1",
      "model": "CAT-20KS",
      "liters": "15",
      "image": "assets/generator3.png",
      "capacity": "70",
      "usage": "15",
    },
  ];

  static final String date = DateUtils.dateOnly(
    DateTime.now(),
  ).toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Reports",
        leadingIconType: LeadingIconType.notification,
        showInfoIcon: true,
        avatarPath: 'assets/profile.png',
      ),
      extendBodyBehindAppBar: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: ListView.builder(
          itemCount: generators.length,
          itemBuilder: (context, index) {
            final generator = generators[index];
            return Slidable(
              key: ValueKey(index),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.2,
                children: [
                  CustomSlidableAction(
                    padding: EdgeInsets.zero,
                    onPressed: (context) => {
                      showConfirmationListDelete(context),
                    },
                    backgroundColor: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 8,
                        bottom: 8,
                        right: 0,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReportPreviewScreen(data: generators[index]),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              generator['name'],
                              maxLines: 1,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Model: ${generator['model']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Location: ${generator['location']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              date,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(129, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 10,
                        child: Column(
                          children: const [
                            Icon(
                              Icons.drag_indicator_sharp,
                              color: Colors.red,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

void showConfirmationListDelete(BuildContext context) {
  showModalBottomSheet(
    useRootNavigator: true,
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, size: 22, color: Colors.black54),
              ),
            ),
            const Text(
              "Are you sure you want to delete ?",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    },
  );
}
