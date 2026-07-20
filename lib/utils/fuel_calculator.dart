class ReportLogEntry {
  final DateTime date;
  final double runtimeHours;
  final double fuelUsed;
  final double fuelBalance;

  ReportLogEntry({
    required this.date,
    required this.runtimeHours,
    required this.fuelUsed,
    required this.fuelBalance,
  });

  @override
  bool operator ==(Object other) =>
      other is ReportLogEntry &&
      other.date == date &&
      other.runtimeHours == runtimeHours &&
      other.fuelUsed == fuelUsed &&
      other.fuelBalance == fuelBalance;

  @override
  int get hashCode => Object.hash(date, runtimeHours, fuelUsed, fuelBalance);

  @override
  String toString() =>
      'ReportLogEntry(date: $date, runtimeHours: $runtimeHours, '
      'fuelUsed: $fuelUsed, fuelBalance: $fuelBalance)';
}

class FuelCalculator {
  static List<ReportLogEntry> buildReportRows({
    required Map<String, double> runtimeByDay,
    required Map<String, double> fuelAddedByDay,
    required double ratedUsagePerHour,
  }) {
    final allDayKeys = {...runtimeByDay.keys, ...fuelAddedByDay.keys}.toList()
      ..sort();

    final rows = <ReportLogEntry>[];
    double runningBalance = 0;

    for (final key in allDayKeys) {
      final date = DateTime.parse(key);
      final hoursThatDay = runtimeByDay[key] ?? 0;
      final fuelAddedThatDay = fuelAddedByDay[key] ?? 0;
      final fuelUsedThatDay = hoursThatDay * ratedUsagePerHour;

      runningBalance = runningBalance + fuelAddedThatDay - fuelUsedThatDay;

      rows.add(
        ReportLogEntry(
          date: date,
          runtimeHours: hoursThatDay,
          fuelUsed: fuelUsedThatDay,
          fuelBalance: runningBalance,
        ),
      );
    }

    return rows;
  }

  static double actualUsageRate({
    required double totalFuelUsed,
    required double totalRuntimeHours,
  }) {
    if (totalRuntimeHours <= 0) return 0;
    return totalFuelUsed / totalRuntimeHours;
  }
}
