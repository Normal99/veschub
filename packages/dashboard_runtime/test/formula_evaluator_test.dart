import 'package:test/test.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';

void main() {
  num? telemetry(String key) => switch (key) {
        'erpm' => 12000,
        'duty' => 0.5,
        'temp.mosfet' => 45.5,
        _ => null,
      };

  group('arithmetic (pre-existing behaviour, regression coverage)', () {
    test('basic operators and precedence', () {
      expect(evaluateFormula('2 + 3 * 4', telemetry), 14);
      expect(evaluateFormula('(2 + 3) * 4', telemetry), 20);
      expect(evaluateFormula('2 ^ 3', telemetry), 8);
      expect(evaluateFormula('-5 + 2', telemetry), -3);
      expect(evaluateFormula('10 / 4', telemetry), 2.5);
    });

    test('telemetry key lookups, including dotted keys', () {
      expect(evaluateFormula('erpm / 1000', telemetry), 12);
      expect(evaluateFormula('temp.mosfet + 1', telemetry), 46.5);
    });

    test('unknown key throws', () {
      expect(() => evaluateFormula('notARealKey', telemetry),
          throwsFormatException);
    });

    test('empty expression evaluates to 0', () {
      expect(evaluateFormula('', telemetry), 0);
    });
  });

  group('function calls', () {
    test('min/max with multiple arguments', () {
      expect(evaluateFormula('min(3, 1, 2)', telemetry), 1);
      expect(evaluateFormula('max(3, 1, 2)', telemetry), 3);
    });

    test('clamp', () {
      expect(evaluateFormula('clamp(150, 0, 100)', telemetry), 100);
      expect(evaluateFormula('clamp(-5, 0, 100)', telemetry), 0);
      expect(evaluateFormula('clamp(50, 0, 100)', telemetry), 50);
    });

    test('abs, round, floor, ceil', () {
      expect(evaluateFormula('abs(-7)', telemetry), 7);
      expect(evaluateFormula('round(4.6)', telemetry), 5);
      expect(evaluateFormula('floor(4.6)', telemetry), 4);
      expect(evaluateFormula('ceil(4.1)', telemetry), 5);
    });

    test('sqrt', () {
      expect(evaluateFormula('sqrt(9)', telemetry), 3.0);
    });

    test('functions compose with arithmetic and telemetry lookups', () {
      // A realistic use: clamp a duty-cycle percentage display to 0-100.
      expect(evaluateFormula('clamp(duty * 100, 0, 100)', telemetry), 50);
      // Nested calls.
      expect(evaluateFormula('max(min(10, 5), 2)', telemetry), 5);
    });

    test('wrong argument count throws', () {
      expect(() => evaluateFormula('clamp(1, 2)', telemetry),
          throwsFormatException);
      expect(() => evaluateFormula('abs(1, 2)', telemetry),
          throwsFormatException);
      expect(() => evaluateFormula('min()', telemetry), throwsFormatException);
    });

    test('unknown function throws', () {
      expect(() => evaluateFormula('bogus(1)', telemetry),
          throwsFormatException);
    });
  });
}
