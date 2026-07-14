import 'dart:async';

import 'package:test/test.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

void main() {
  late TelemetryStore store;

  setUp(() => store = TelemetryStore());
  tearDown(() => store.dispose());

  test('update stores latest value', () {
    store.update(TelemetryKey.erpm, 1000);
    expect(store.value(TelemetryKey.erpm), 1000);
    expect(store.contains(TelemetryKey.erpm), isTrue);
    expect(store.contains(TelemetryKey.duty), isFalse);
  });

  test('watch replays last value then emits updates', () async {
    store.update(TelemetryKey.vIn, 42.0);
    final events = <dynamic>[];
    final sub = store.watch(TelemetryKey.vIn).listen(events.add);
    store.update(TelemetryKey.vIn, 42.5);
    store.update(TelemetryKey.vIn, 43.0);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(events, [42.0, 42.5, 43.0]);
  });

  test('watch without prior value only emits updates', () async {
    final events = <dynamic>[];
    final sub = store.watch(TelemetryKey.duty).listen(events.add);
    store.update(TelemetryKey.duty, 0.5);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(events, [0.5]);
  });

  test('ingest writes a snapshot under canonical keys', () {
    store.ingest({
      TelemetryKey.erpm: 5000,
      TelemetryKey.duty: 0.8,
      TelemetryKey.vIn: 50.1,
    });
    expect(store.value(TelemetryKey.erpm), 5000);
    expect(store.value(TelemetryKey.duty), 0.8);
    expect(store.value(TelemetryKey.vIn), 50.1);
  });

  test('keys reflects what has been written', () {
    store.update(TelemetryKey.erpm, 1);
    store.update(TelemetryKey.gpsLat, 59.9);
    expect(store.keys.toSet(), {TelemetryKey.erpm, TelemetryKey.gpsLat});
  });
}
