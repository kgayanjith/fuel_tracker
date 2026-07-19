import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fuel_tracker/screens/generators.dart';
import 'package:fuel_tracker/widgets/appbar.dart';

class ReportPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReportPreviewScreen({super.key, required this.data});

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportLogRow {
  final DateTime date;
  final double runtimeHours;
  final double fuelUsed;
  final double fuelBalance;

  _ReportLogRow({
    required this.date,
    required this.runtimeHours,
    required this.fuelUsed,
    required this.fuelBalance,
  });
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  bool _isLoading = true;
  String? _error;
  List<_ReportLogRow> _rows = [];
  double _totalRuntimeHours = 0;
  double _totalFuelUsed = 0;
  double _actualUsageRate = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _formattedDate {
    final createdAt = widget.data['createdAt'];
    DateTime? dt;
    if (createdAt is Timestamp) {
      dt = createdAt.toDate();
    } else if (createdAt is DateTime) {
      dt = createdAt;
    }
    if (dt == null) return '-';
    return DateUtils.dateOnly(dt).toIso8601String().split('T').first;
  }

  Future<void> _loadData() async {
    final generatorId = widget.data['generatorId'] as String?;
    final ratedUsagePerHour =
        (widget.data['fuelUsage'] as num?)?.toDouble() ?? 0;

    if (generatorId == null) {
      setState(() {
        _isLoading = false;
        _error = 'No generator linked to this report';
      });
      return;
    }

    try {
      final runtimeSnap = await FirebaseFirestore.instance
          .collection('runtime_logs')
          .where('generatorId', isEqualTo: generatorId)
          .get();

      final fuelSnap = await FirebaseFirestore.instance
          .collection('fuel_logs')
          .where('generatorId', isEqualTo: generatorId)
          .get();

      // Group runtime hours by day.
      final Map<String, double> runtimeByDay = {};
      for (final doc in runtimeSnap.docs) {
        final d = doc.data();
        final ts = d['date'];
        if (ts is! Timestamp) continue;
        final day = DateUtils.dateOnly(ts.toDate());
        final key = day.toIso8601String();
        final hours = (d['hours'] as num?)?.toDouble() ?? 0;
        final minutes = (d['minutes'] as num?)?.toDouble() ?? 0;
        final totalHours = hours + (minutes / 60);
        runtimeByDay[key] = (runtimeByDay[key] ?? 0) + totalHours;
      }

      final Map<String, double> fuelAddedByDay = {};
      for (final doc in fuelSnap.docs) {
        final d = doc.data();
        final ts = d['date'];
        if (ts is! Timestamp) continue;
        final day = DateUtils.dateOnly(ts.toDate());
        final key = day.toIso8601String();
        final liters = (d['liters'] as num?)?.toDouble() ?? 0;
        fuelAddedByDay[key] = (fuelAddedByDay[key] ?? 0) + liters;
      }

      final allDayKeys = {...runtimeByDay.keys, ...fuelAddedByDay.keys}.toList()
        ..sort();

      final rows = <_ReportLogRow>[];
      double runningBalance = 0;
      double totalRuntime = 0;
      double totalUsed = 0;

      for (final key in allDayKeys) {
        final date = DateTime.parse(key);
        final hoursThatDay = runtimeByDay[key] ?? 0;
        final fuelAddedThatDay = fuelAddedByDay[key] ?? 0;
        final fuelUsedThatDay = hoursThatDay * ratedUsagePerHour;

        runningBalance = runningBalance + fuelAddedThatDay - fuelUsedThatDay;
        totalRuntime += hoursThatDay;
        totalUsed += fuelUsedThatDay;

        rows.add(
          _ReportLogRow(
            date: date,
            runtimeHours: hoursThatDay,
            fuelUsed: fuelUsedThatDay,
            fuelBalance: runningBalance,
          ),
        );
      }

      setState(() {
        _rows = rows;
        _totalRuntimeHours = totalRuntime;
        _totalFuelUsed = totalUsed;
        _actualUsageRate = totalRuntime > 0 ? totalUsed / totalRuntime : 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load report data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Report Preview",
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!))
                  : SingleChildScrollView(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _info(
                                        'Name',
                                        widget.data['name']?.toString() ?? '',
                                      ),
                                      _info(
                                        'Location',
                                        widget.data['location']?.toString() ??
                                            '',
                                      ),
                                      _info(
                                        'Code',
                                        widget.data['code']?.toString() ?? '',
                                      ),
                                      _info(
                                        'Estimated fuel usage',
                                        '${widget.data['fuelUsage'] ?? '-'} L/hr',
                                      ),
                                      _info(
                                        'Actual fuel usage',
                                        _totalRuntimeHours > 0
                                            ? '${_actualUsageRate.toStringAsFixed(2)} L/hr'
                                            : 'No runtime data yet',
                                      ),
                                      _info(
                                        'Fuel capacity',
                                        '${widget.data['fuelCapacity'] ?? '-'} L',
                                      ),
                                      _info(
                                        'Total runtime',
                                        '${_totalRuntimeHours.toStringAsFixed(1)} hrs',
                                      ),
                                      _info(
                                        'Total fuel consumed',
                                        '${_totalFuelUsed.toStringAsFixed(1)} L',
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  'Created : $_formattedDate',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _rows.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Text(
                                      'No runtime or fuel entries logged yet '
                                      'for this generator.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  )
                                : Table(
                                    border: TableBorder.all(
                                      color: Colors.black87,
                                    ),
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
                                      ..._rows.map(
                                        (log) => _row([
                                          log.date
                                              .toIso8601String()
                                              .split('T')
                                              .first,
                                          log.runtimeHours.toStringAsFixed(1),
                                          log.fuelUsed.toStringAsFixed(1),
                                          log.fuelBalance.toStringAsFixed(1),
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
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
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
