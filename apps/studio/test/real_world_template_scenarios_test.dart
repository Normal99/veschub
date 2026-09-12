import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:templates/templates.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('Tier 4: Real-World E2E Application Template Scenarios', () {
    testWidgets('Scenario 1: Minimal Dashboard Template E2E (Gauge editing & live RPM telemetry)', (tester) async {
      final template = Templates.minimal;
      expect(template.id, equals('minimal'));

      // Apply knob edit to minimal template
      final doc = template.applyEdits({
        'rpm.max': 35000,
        'rpm.color': 0xFF0288D1,
      });

      final rpmWidget = doc.widgets.singleWhere((w) => w.id == 'rpm');
      final store = TelemetryStore();
      store.updateFromMap({'erpm': 18500.0});

      final resolvedProps = <String, dynamic>{};
      for (final entry in rpmWidget.properties.entries) {
        final val = entry.value.map(
          literal: (b) => b.value,
          telemetry: (b) => store.value(b.key),
          graph: (_) => null,
          formula: (_) => null,
        );
        if (val != null) resolvedProps[entry.key] = val;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            backgroundColor: Color(doc.background),
            body: SizedBox(
              width: doc.canvas.width,
              height: doc.canvas.height,
              child: buildWidget(rpmWidget, resolvedProps),
            ),
          ),
        ),
      );

      expect(find.byType(GaugeWidget), findsOneWidget);
      expect(resolvedProps['value'], equals(18500.0));
      expect(resolvedProps['max'], equals(35000));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scenario 2: Performance Dashboard Template E2E (Multi-widget layout & live current chart)', (tester) async {
      final template = Templates.performance;
      expect(template.document.widgets.length, equals(4));

      final store = TelemetryStore();
      store.updateFromMap({
        'erpm': 28000.0,
        'duty': 0.82,
        'v_in': 51.2,
        'current.motor': 34.5,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: template.document.widgets.map((w) {
                final resolved = <String, dynamic>{};
                for (final entry in w.properties.entries) {
                  final val = entry.value.map(
                    literal: (b) => b.value,
                    telemetry: (b) => store.value(b.key),
                    graph: (_) => null,
                    formula: (_) => null,
                  );
                  if (val != null) resolved[entry.key] = val;
                }
                return Expanded(child: buildWidget(w, resolved));
              }).toList(),
            ),
          ),
        ),
      );

      expect(find.byType(GaugeWidget), findsOneWidget);
      expect(find.byType(BarWidget), findsOneWidget);
      expect(find.byType(TextWidget), findsOneWidget);
      expect(find.byType(ChartWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scenario 3: Commuter Dashboard Template E2E (Battery Range & Status Fault Alarm)', (tester) async {
      final template = Templates.commuter;
      final store = TelemetryStore();
      store.updateFromMap({
        'speed': 45.0,
        'duty': 0.55,
        'battery_level': 0.72,
        'temp.mosfet': 38.5,
        'fault': 0, // No fault initial
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: template.document.widgets.map((w) {
                final resolved = <String, dynamic>{};
                for (final entry in w.properties.entries) {
                  final val = entry.value.map(
                    literal: (b) => b.value,
                    telemetry: (b) => store.value(b.key),
                    graph: (_) => null,
                    formula: (_) => null,
                  );
                  if (val != null) resolved[entry.key] = val;
                }
                return SizedBox(
                  height: 120,
                  child: buildWidget(w, resolved),
                );
              }).toList(),
            ),
          ),
        ),
      );

      expect(find.byType(GaugeWidget), findsOneWidget);
      expect(find.byType(BatteryRangeWidget), findsOneWidget);
      expect(find.byType(StatusWidget), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Trigger Fault Alarm Telemetry Event
      store.updateFromMap({'fault': 4}); // Over-voltage fault
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scenario 4: Off-Road Dashboard Template E2E with Canvas Car Viz Addition', (tester) async {
      final template = Templates.offRoad;
      final store = TelemetryStore();
      store.updateFromMap({
        'erpm': 32000.0,
        'duty': 0.90,
        'temp.mosfet': 65.0,
        'temp.motor': 72.0,
        'current.motor': 58.0,
        'fault': 0,
      });

      // Add a CarViz widget to OffRoad document
      final carVizWidget = const WidgetInstance(
        id: 'car_viz_offroad',
        kind: 'car_viz',
        properties: {
          'doorLeft': Binding.literal(value: false),
          'doorRight': Binding.literal(value: false),
          'showRing': Binding.literal(value: true),
          'showLabels': Binding.literal(value: true),
          'label': Binding.literal(value: 'Vehicle Proximity'),
        },
      );

      final widgets = [...template.document.widgets, carVizWidget];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: widgets.map((w) {
                  final resolved = <String, dynamic>{};
                  for (final entry in w.properties.entries) {
                    final val = entry.value.map(
                      literal: (b) => b.value,
                      telemetry: (b) => store.value(b.key),
                      graph: (_) => null,
                      formula: (_) => null,
                    );
                    if (val != null) resolved[entry.key] = val;
                  }
                  return SizedBox(
                    height: 150,
                    child: buildWidget(w, resolved),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(find.text('Vehicle Proximity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Scenario 5: Tesla Model 3 Advanced Template E2E Execution & Telemetry Stream Updates', (tester) async {
      final teslaTemplate = advancedDashboardTemplates.firstWhere((t) => t.id == 'tesla-model3');
      expect(teslaTemplate.name, equals('Tesla Model 3'));

      final store = TelemetryStore();
      store.updateFromMap({
        'speed': 105.0,
        'odometer': 14250.0,
        'power': 42.0,
        'trip_distance': 18.4,
        'energy_used': 3.2,
        'avg_speed': 54.0,
        'range': 340.0,
        'temp.mosfet': 32.0,
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: teslaTemplate.document.widgets.map((w) {
                  final resolved = <String, dynamic>{};
                  for (final entry in w.properties.entries) {
                    final val = entry.value.map(
                      literal: (b) => b.value,
                      telemetry: (b) => store.value(b.key),
                      graph: (_) => null,
                      formula: (_) => null,
                    );
                    if (val != null) resolved[entry.key] = val;
                  }
                  return SizedBox(
                    height: 150,
                    child: buildWidget(w, resolved),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GaugeWidget), findsOneWidget);
      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(find.byType(TripStatsWidget), findsOneWidget);
      expect(find.byType(BatteryRangeWidget), findsOneWidget);
      expect(find.byType(GearSelectorWidget), findsOneWidget);
      expect(find.byType(WarningsWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
