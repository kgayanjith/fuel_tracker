import 'package:flutter/material.dart';
import 'package:fuel_tracker/screens/generators.dart';
import 'package:fuel_tracker/widgets/appbar.dart';

class ReportPreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReportPreviewScreen({super.key, required this.data});

  static const String actualFuel = '12L';

  static final String date = DateUtils.dateOnly(
    DateTime.now(),
  ).toIso8601String().split('T').first;

  static const List<Map<String, String>> logs = [
    {
      'date': '2025-08-20',
      'runtime': '2',
      'fuelUsage': '20',
      'fuelBalance': '10',
    },
    {
      'date': '2025-08-25',
      'runtime': '1',
      'fuelUsage': '10',
      'fuelBalance': '0',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Add Generator",
        leadingIconType: LeadingIconType.back,
        showInfoIcon: true,
        avatarPath: 'assets/profile.png',
        onLeadingIconTap: () => Navigator.pop(context),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 35),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black87, width: 1.5),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _info('Name', data['name']),
                                _info('Location', data['location']),
                                _info('Code', data['model']),
                                _info('Estimated fuel usage', data['usage']),
                                _info('Actual fuel usage', actualFuel),
                                _info('Fuel capacity', data['capacity']),
                              ],
                            ),
                          ),
                          Text(
                            'Created : $date',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Table(
                        border: TableBorder.all(color: Colors.black87),
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(1.5),
                          2: FlexColumnWidth(1.5),
                          3: FlexColumnWidth(1.8),
                        },
                        children: [
                          _row([
                            'Date',
                            'Runtime (Hr)',
                            'Fuel Usage (L)',
                            'Fuel Balance (L)',
                          ], isHeader: true),
                          ...logs.map(
                            (log) => _row([
                              log['date']!,
                              log['runtime']!,
                              log['fuelUsage']!,
                              log['fuelBalance']!,
                            ]),
                          ),
                        ],
                      ),
                      SizedBox(height: 200),
                    ],
                  ),
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const GeneratorsScreen(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                                const begin = Offset(-1.0, 0.0);
                                const end = Offset.zero;
                                final tween = Tween(
                                  begin: begin,
                                  end: end,
                                ).chain(CurveTween(curve: Curves.easeInOut));
                                return SlideTransition(
                                  position: animation.drive(tween),
                                  child: child,
                                );
                              },
                        ),
                      ),
                    },
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEEEEE),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Cancle',
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
                    onTap: () => {},
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Export',
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
            SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          TextSpan(text: value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    ),
  );

  TableRow _row(List<String> cells, {bool isHeader = false}) => TableRow(
    children: cells
        .map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              c,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        )
        .toList(),
  );
}
