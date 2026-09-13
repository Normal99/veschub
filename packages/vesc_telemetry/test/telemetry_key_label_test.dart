import 'package:test/test.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

void main() {
  test('every canonical key has a real, distinct human-readable label', () {
    final labels = <String>{};
    for (final key in TelemetryKey.all) {
      final label = telemetryKeyLabel(key);
      // The whole point: a beginner shouldn't just see the raw key back.
      expect(label, isNot(equals(key)),
          reason: '$key has no friendly label — falls back to itself');
      labels.add(label);
    }
    expect(labels.length, TelemetryKey.all.length,
        reason: 'two different keys ended up with the same label');
  });

  test('an unknown/custom key falls back to itself, not a crash', () {
    expect(telemetryKeyLabel('my_custom_lispbm_var'), 'my_custom_lispbm_var');
  });
}
