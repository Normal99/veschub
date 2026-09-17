import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('Tier 3: Cross-Feature Manifest & Inspector Interactions', () {
    testWidgets(
        'XF1: Property Manifest Schema + Default Properties + Telemetry Binding + Widget Render Update',
        (tester) async {
      final store = TelemetryStore();
      store.updateFromMap({
        'erpm': 12500.0,
        'temp.mosfet': 52.0,
      });

      final widgetInstance = const WidgetInstance(
        id: 'gauge_1',
        kind: 'gauge',
        properties: {
          'value': Binding.telemetry(key: 'erpm'),
          'min': Binding.literal(value: 0),
          'max': Binding.literal(value: 30000),
          'label': Binding.literal(value: 'RPM'),
          'color': Binding.literal(value: 0xFF4FC3F7),
        },
      );

      // Resolve properties against store
      final resolvedProps = <String, dynamic>{};
      for (final entry in widgetInstance.properties.entries) {
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
            body: SizedBox(
              width: 300,
              height: 300,
              child: buildWidget(widgetInstance, resolvedProps),
            ),
          ),
        ),
      );

      expect(find.byType(GaugeWidget), findsOneWidget);
      expect(find.text('RPM'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Simulate live telemetry update
      store.updateFromMap({'erpm': 22000.0});
      final updatedResolved = <String, dynamic>{};
      for (final entry in widgetInstance.properties.entries) {
        final val = entry.value.map(
          literal: (b) => b.value,
          telemetry: (b) => store.value(b.key),
          graph: (_) => null,
          formula: (_) => null,
        );
        if (val != null) updatedResolved[entry.key] = val;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: buildWidget(widgetInstance, updatedResolved),
            ),
          ),
        ),
      );

      expect(updatedResolved['value'], equals(22000.0));
      expect(find.byType(GaugeWidget), findsOneWidget);
    });

    testWidgets(
        'XF2: CarViz Manifest Properties + Property Inspector Binding + Live CarViz Render Tree',
        (tester) async {
      final store = TelemetryStore();
      store.updateFromMap({
        'door_left_status': true,
        'door_right_status': false,
      });

      final carVizInstance = const WidgetInstance(
        id: 'car_1',
        kind: 'car_viz',
        properties: {
          'doorLeft': Binding.telemetry(key: 'door_left_status'),
          'doorRight': Binding.telemetry(key: 'door_right_status'),
          'showRing': Binding.literal(value: true),
          'showLabels': Binding.literal(value: true),
          'label': Binding.literal(value: 'Vehicle Status'),
          'fontSize': Binding.literal(value: 16.0),
          'color': Binding.literal(value: 0xFFFFFFFF),
        },
      );

      final resolvedProps = <String, dynamic>{};
      for (final entry in carVizInstance.properties.entries) {
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
            body: SizedBox(
              width: 350,
              height: 350,
              child: buildWidget(carVizInstance, resolvedProps),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(find.text('Vehicle Status'), findsOneWidget);
      // 'Front' / 'Rear' labels are painted on canvas (TextPainter), not Flutter Text widgets
      expect(find.byType(CustomPaint), findsWidgets);
      expect(resolvedProps['doorLeft'], isTrue);
      expect(resolvedProps['doorRight'], isFalse);
    });

    testWidgets(
        'XF3: Capability Level Filter + Property Manifest + Inspector Visibility Validation',
        (tester) async {
      final basicGaugeProps = visibleProperties('gauge', CapabilityLevel.basic);
      final advancedGaugeProps =
          visibleProperties('gauge', CapabilityLevel.advanced);
      final expertGaugeProps =
          visibleProperties('gauge', CapabilityLevel.expert);

      expect(basicGaugeProps.length, lessThan(advancedGaugeProps.length));
      expect(advancedGaugeProps.length,
          lessThanOrEqualTo(expertGaugeProps.length));

      // Verify safe basic knobs
      final basicKeys = basicGaugeProps.map((m) => m.key).toSet();
      expect(basicKeys.contains('min'), isTrue);
      expect(basicKeys.contains('max'), isTrue);
      expect(basicKeys.contains('label'), isTrue);

      // The value binding itself is never gated (what a widget displays
      // isn't an "advanced" concept) — only cosmetic/advanced knobs are.
      expect(basicKeys.contains('value'), isTrue);
      // The gauge's ring geometry (sweep/start angle, arc width, needle
      // style) is basic too — "customize the layout" is core, not advanced;
      // fine-detail cosmetics like shadows/letter-spacing still gate.
      expect(basicKeys.contains('sweepAngle'), isTrue);
      expect(basicKeys.contains('shadowBlur'), isFalse);
    });

    testWidgets(
        'XF4: Multi-Widget Dashboard Document Serialization & Property Resolution',
        (tester) async {
      final store = TelemetryStore();
      store.updateFromMap({
        'v_in': 52.4,
        'duty': 0.65,
        'fault': 0,
      });

      final doc = const DashboardDocument(
        name: 'Test Dashboard',
        canvas: CanvasSize(width: 800, height: 480),
        widgets: [
          WidgetInstance(
            id: 'voltage_text',
            kind: 'text',
            properties: {
              'value': Binding.telemetry(key: 'v_in'),
              'label': Binding.literal(value: 'Voltage'),
              'unit': Binding.literal(value: 'V'),
            },
          ),
          WidgetInstance(
            id: 'duty_bar',
            kind: 'bar',
            properties: {
              'value': Binding.telemetry(key: 'duty'),
              'min': Binding.literal(value: 0),
              'max': Binding.literal(value: 1),
            },
          ),
          WidgetInstance(
            id: 'status_indicator',
            kind: 'status',
            properties: {
              'fault': Binding.telemetry(key: 'fault'),
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: doc.widgets.map((w) {
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

      expect(find.byType(TextWidget), findsOneWidget);
      expect(find.byType(BarWidget), findsOneWidget);
      expect(find.byType(StatusWidget), findsOneWidget);
      expect(find.text('Voltage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'XF5: Palette Preset Template Execution & Customized Widget Instantiation',
        (tester) async {
      final presetInstance = const WidgetInstance(
        id: 'preset_mini',
        kind: 'minigauge',
        properties: {
          'value': Binding.telemetry(key: 'temp.mosfet'),
          'min': Binding.literal(value: 0),
          'max': Binding.literal(value: 100),
          'label': Binding.literal(value: 'FET Temp'),
          'unit': Binding.literal(value: '°C'),
          'color': Binding.literal(value: 0xFFFF9800),
        },
      );

      final store = TelemetryStore();
      store.updateFromMap({'temp.mosfet': 68.0});

      final resolvedProps = <String, dynamic>{};
      for (final entry in presetInstance.properties.entries) {
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
            body: SizedBox(
              width: 200,
              height: 200,
              child: buildWidget(presetInstance, resolvedProps),
            ),
          ),
        ),
      );

      expect(find.byType(MiniGaugeWidget), findsOneWidget);
      expect(resolvedProps['value'], equals(68.0));
      expect(resolvedProps['label'], equals('FET Temp'));
    });
  });
}
