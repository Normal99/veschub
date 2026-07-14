import 'dart:async';

import 'package:test/test.dart';
import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

void main() {
  late TelemetryStore store;
  late DashboardRuntime runtime;

  const doc = DashboardDocument(
    canvas: CanvasSize(width: 800, height: 480),
    widgets: [
      WidgetInstance(
        id: 'g1',
        kind: 'gauge',
        properties: {
          'max': Binding.literal(value: 30000),
          'value': Binding.telemetry(key: TelemetryKey.erpm),
          'label': Binding.literal(value: 'RPM'),
        },
      ),
      WidgetInstance(
        id: 't1',
        kind: 'text',
        properties: {
          'value': Binding.telemetry(key: TelemetryKey.vIn),
        },
      ),
    ],
  );

  setUp(() {
    store = TelemetryStore();
    runtime = DashboardRuntime(document: doc, store: store);
  });

  tearDown(() {
    runtime.dispose();
    store.dispose();
  });

  test('emits all widgets on start with literals resolved', () async {
    runtime.start();
    final events = <Map<String, Map<String, dynamic>>>[];
    final sub = runtime.dirtyWidgets.listen(events.add);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(events, hasLength(1));
    final dirty = events.single;
    // Unbound telemetry keys are unresolved -> absent; literals present.
    expect(dirty['g1']!['max'], 30000);
    expect(dirty['g1']!['label'], 'RPM');
    expect(dirty['g1']!.containsKey('value'), isFalse);
    expect(dirty['t1']!.containsKey('value'), isFalse);
  });

  test('emits only changed widgets when telemetry updates', () async {
    runtime.start();
    final events = <Map<String, Map<String, dynamic>>>[];
    final sub = runtime.dirtyWidgets.listen(events.add);

    // First flush: initial state.
    await Future<void>.delayed(Duration.zero);
    store.update(TelemetryKey.erpm, 5000);
    await Future<void>.delayed(Duration.zero);
    store.update(TelemetryKey.vIn, 42.0);
    await Future<void>.delayed(Duration.zero);
    // Update erpm again to same value -> no new event.
    store.update(TelemetryKey.erpm, 5000);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    // event[0] = initial, event[1] = erpm widget, event[2] = vIn widget, then none.
    expect(events, hasLength(3));
    expect(events[1].keys.toSet(), {'g1'});
    expect(events[1]['g1']!['value'], 5000);
    expect(events[2].keys.toSet(), {'t1'});
    expect(events[2]['t1']!['value'], 42.0);
  });

  test('setDocument re-evaluates everything', () async {
    runtime.start();
    final events = <Map<String, Map<String, dynamic>>>[];
    final sub = runtime.dirtyWidgets.listen(events.add);
    await Future<void>.delayed(Duration.zero);
    events.clear();

    runtime.setDocument(
      const DashboardDocument(
        canvas: CanvasSize(width: 800, height: 480),
        widgets: [
          WidgetInstance(
            id: 'b1',
            kind: 'bar',
            properties: {'value': Binding.literal(value: 99)},
          ),
        ],
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(events, hasLength(1));
    expect(events.single.keys.toSet(), {'b1'});
    expect(events.single['b1']!['value'], 99);
  });
}
