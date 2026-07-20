import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_tracker/utils/fuel_calculator.dart';

void main() {
  group('FuelCalculator.buildReportRows', () {
    test('calculates fuel usage and running balance across multiple days', () {
      final runtimeByDay = {
        '2025-08-20T00:00:00.000': 2.0,
        '2025-08-25T00:00:00.000': 1.0,
      };
      final fuelAddedByDay = {'2025-08-20T00:00:00.000': 30.0};
      const ratedUsagePerHour = 10.0;

      final rows = FuelCalculator.buildReportRows(
        runtimeByDay: runtimeByDay,
        fuelAddedByDay: fuelAddedByDay,
        ratedUsagePerHour: ratedUsagePerHour,
      );

      expect(rows.length, 2);

      expect(rows[0].runtimeHours, 2.0);
      expect(rows[0].fuelUsed, 20.0);
      expect(rows[0].fuelBalance, 10.0);

      expect(rows[1].runtimeHours, 1.0);
      expect(rows[1].fuelUsed, 10.0);
      expect(rows[1].fuelBalance, 0.0);
    });

    test('returns an empty list when there is no activity', () {
      final rows = FuelCalculator.buildReportRows(
        runtimeByDay: {},
        fuelAddedByDay: {},
        ratedUsagePerHour: 10.0,
      );

      expect(rows, isEmpty);
    });
  });

  group('FuelCalculator.actualUsageRate', () {
    test('computes liters per hour correctly', () {
      final rate = FuelCalculator.actualUsageRate(
        totalFuelUsed: 30.0,
        totalRuntimeHours: 3.0,
      );
      expect(rate, 10.0);
    });

    test(
      'returns 0 when there is no runtime logged, avoiding division by zero',
      () {
        final rate = FuelCalculator.actualUsageRate(
          totalFuelUsed: 15.0,
          totalRuntimeHours: 0,
        );
        expect(rate, 0.0);
      },
    );
  });
}
