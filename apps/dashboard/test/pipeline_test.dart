import 'dart:async';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_sim/vesc_sim.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:vesc_transport/vesc_transport.dart';

import 'package:dashboard/main.dart';

void main() {
  group('End-to-end VESC pipeline', () {
    late VirtualTransportPair pair;
    late VescSim sim;
    late TelemetryStore store;

    setUp(() {
      pair = VirtualTransportPair();
      sim = VescSim(pair.a);
      store = TelemetryStore();
    });

    tearDown(() async {
      sim.stop();
      pair.close();
      store.dispose();
    });

    test('decodes telemetry and ingests all 16 keys', () async {
      final completer = Completer<void>();
      var frameCount = 0;

      final rxSub = pair.b.payloads.listen((payload) {
        try {
          final v = TelemetryValues.fromPayload(payload);
          store.ingest({
            TelemetryKey.erpm: v.erpm,
            TelemetryKey.duty: v.duty,
            TelemetryKey.vIn: v.vIn,
            TelemetryKey.tempMosfet: v.tempMosfet,
            TelemetryKey.tempMotor: v.tempMotor,
            TelemetryKey.currentMotor: v.currentMotor,
            TelemetryKey.currentInput: v.currentInput,
            TelemetryKey.focId: v.id,
            TelemetryKey.focIq: v.iq,
            TelemetryKey.ampHoursCharged: v.ampHoursCharged,
            TelemetryKey.ampHoursDischarged: v.ampHoursDischarged,
            TelemetryKey.wattHoursCharged: v.wattHoursCharged,
            TelemetryKey.wattHoursDischarged: v.wattHoursDischarged,
            TelemetryKey.tachometer: v.tachometer,
            TelemetryKey.tachometerAbs: v.tachometerAbs,
            TelemetryKey.fault: v.fault.code,
          });
          frameCount++;
          if (frameCount >= 2) completer.complete();
        } catch (_) {}
      });

      await pair.b.connect();
      await sim.clientTransport.connect();
      sim.start();

      await completer.future.timeout(const Duration(seconds: 5));

      expect(frameCount, greaterThanOrEqualTo(2));
      expect(store.contains(TelemetryKey.erpm), isTrue);
      expect(store.contains(TelemetryKey.duty), isTrue);
      expect(store.contains(TelemetryKey.vIn), isTrue);
      expect(store.contains(TelemetryKey.tempMosfet), isTrue);
      expect(store.contains(TelemetryKey.tempMotor), isTrue);
      expect(store.contains(TelemetryKey.currentMotor), isTrue);
      expect(store.contains(TelemetryKey.currentInput), isTrue);
      expect(store.contains(TelemetryKey.focId), isTrue);
      expect(store.contains(TelemetryKey.focIq), isTrue);
      expect(store.contains(TelemetryKey.ampHoursCharged), isTrue);
      expect(store.contains(TelemetryKey.ampHoursDischarged), isTrue);
      expect(store.contains(TelemetryKey.wattHoursCharged), isTrue);
      expect(store.contains(TelemetryKey.wattHoursDischarged), isTrue);
      expect(store.contains(TelemetryKey.tachometer), isTrue);
      expect(store.contains(TelemetryKey.tachometerAbs), isTrue);
      expect(store.contains(TelemetryKey.fault), isTrue);

      final erpm = store.value(TelemetryKey.erpm);
      expect(erpm, isA<num>());
      expect(store.value(TelemetryKey.fault), equals(0));

      await rxSub.cancel();
    });

    test('resolves bindings and emits dirty widgets', () async {
      final doc = sampleDocument();
      final runtime = DashboardRuntime(document: doc, store: store);
      StreamSubscription<List<int>>? rx;

      pair.b.connect().ignore();
      rx = pair.b.payloads.listen((payload) {
        try {
          final v = TelemetryValues.fromPayload(payload);
          store.ingest({
            TelemetryKey.erpm: v.erpm,
            TelemetryKey.duty: v.duty,
            TelemetryKey.vIn: v.vIn,
            TelemetryKey.currentMotor: v.currentMotor,
            TelemetryKey.currentInput: v.currentInput,
            TelemetryKey.tempMosfet: v.tempMosfet,
          });
        } catch (_) {}
      });

      await sim.clientTransport.connect();
      sim.start();

      final completer = Completer<void>();
      var dirtyCount = 0;
      final dirtySub = runtime.dirtyWidgets.listen((_) {
        dirtyCount++;
        if (dirtyCount >= 2 && !completer.isCompleted) completer.complete();
      });

      runtime.start();

      await completer.future.timeout(const Duration(seconds: 3));

      final rpm = runtime.resolvedFor('rpm');
      expect(rpm['value'], isA<num>(),
          reason: 'rpm gauge should have a numeric value');
      expect(rpm['min'], equals(-30000));
      expect(rpm['max'], equals(30000));
      expect(rpm['label'], equals('RPM'));

      await dirtySub.cancel();
      await rx.cancel();
      runtime.dispose();
    });

    test('formula binding evaluates expression', () {
      store.ingest({TelemetryKey.erpm: 15000, TelemetryKey.vIn: 50});

      const formulaBinding = Binding.formula(expression: 'erpm / 1000');
      final result = resolveBinding(formulaBinding, store);
      expect(result.isResolved, isTrue);
      expect(result.value, equals(15.0));

      const complexBinding =
          Binding.formula(expression: 'v_in * 2 + erpm / 15000');
      final complex = resolveBinding(complexBinding, store);
      expect(complex.isResolved, isTrue);
      expect(complex.value, equals(101.0));
    });
  });
}
