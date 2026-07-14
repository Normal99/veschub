import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('formatNumber', () {
    test('whole numbers with decimals=0 have no point', () {
      expect(formatNumber(42, decimals: 0), '42');
      expect(formatNumber(0, decimals: 0), '0');
    });

    test('groups thousands', () {
      expect(formatNumber(12300, decimals: 0), '12,300');
      expect(formatNumber(-12300, decimals: 0), '-12,300');
    });

    test('decimals for small values', () {
      expect(formatNumber(42.5, decimals: 1), '42.5');
      expect(formatNumber(0.785, decimals: 3), '0.785');
    });

    test('NaN returns placeholder', () {
      expect(formatNumber(double.nan), '--');
      expect(formatNumber(double.infinity), '--');
    });
  });

  group('unit formatters', () {
    test('formatVolts', () {
      expect(formatVolts(50.12), '50.1 V');
    });

    test('formatAmps', () {
      expect(formatAmps(-12.0), '-12.0 A');
    });

    test('formatCelsius', () {
      expect(formatCelsius(45.6), '46 °C');
    });

    test('formatDistance km threshold', () {
      expect(formatDistance(999), '999 m');
      expect(formatDistance(1500), '1.50 km');
    });

    test('formatWattHours kWh threshold', () {
      expect(formatWattHours(500), '500.0 Wh');
      expect(formatWattHours(1500), '1.50 kWh');
    });
  });

  group('erpmToWheelRpm / speed', () {
    test('divides by pole pairs', () {
      expect(erpmToWheelRpm(14000, motorPoles: 14), 2000);
    });

    test('speed from wheel rpm', () {
      // 100 mm wheel, 600 rpm → circumference 0.314 m, 10 r/s → 3.14 m/s
      final v = wheelRpmToSpeed(600, 100);
      expect(v, closeTo(3.14, 0.01));
    });
  });

  group('DashboardTheme', () {
    test('fromDocument resolves colours', () {
      final t = DashboardTheme.fromDocument(
        backgroundArgb: 0xFF000000,
        accentArgb: 0xFFFFFFFF,
      );
      expect(t.background, const Color(0xFF000000));
      expect(t.accent, const Color(0xFFFFFFFF));
      expect(t.brightness, Brightness.dark);
      expect(t.foreground, const Color(0xFFFFFFFF));
    });

    test('light theme has dark foreground', () {
      final t = DashboardTheme.fromDocument(
        backgroundArgb: 0xFFFAFAFA,
        accentArgb: 0xFF1565C0,
        brightness: Brightness.light,
      );
      expect(t.foreground, const Color(0xFF212121));
    });
  });
}
