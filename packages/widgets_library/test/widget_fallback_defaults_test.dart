import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  final Map<String, Widget Function(Map<String, dynamic> props)> widgetBuilders = {
    'gauge': (props) => GaugeWidget(properties: props),
    'bar': (props) => BarWidget(properties: props),
    'text': (props) => TextWidget(properties: props),
    'chart': (props) => ChartWidget(properties: props),
    'status': (props) => StatusWidget(properties: props),
    'minigauge': (props) => MiniGaugeWidget(properties: props),
    'battery_range': (props) => BatteryRangeWidget(properties: props),
    'tripstats': (props) => TripStatsWidget(properties: props),
    'car_viz': (props) => CarVizWidget(properties: props),
    'power_flow': (props) => PowerFlowWidget(properties: props),
    'gear_selector': (props) => GearSelectorWidget(properties: props),
  };

  group('Widget Fallback Defaults & Resiliency (All 11 Core Kinds)', () {
    for (final entry in widgetBuilders.entries) {
      final kind = entry.key;
      final builder = entry.value;

      testWidgets('T1: $kind renders cleanly with empty property map ({})', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250,
                height: 250,
                child: builder({}),
              ),
            ),
          ),
        );

        final expectedClassName = '${kind.replaceAll('_', '')}widget';
        expect(find.byWidgetPredicate((w) => w.runtimeType.toString().toLowerCase() == expectedClassName), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('T2.1: $kind handles explicit null values for common properties safely', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250,
                height: 250,
                child: builder({
                  'value': null,
                  'min': null,
                  'max': null,
                  'color': null,
                  'label': null,
                  'unit': null,
                  'fontSize': null,
                  'padding': null,
                  'borderRadius': null,
                  'opacity': null,
                  'visible': null,
                }),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('T2.2: $kind handles invalid type assignments without crashing', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 250,
                height: 250,
                child: builder({
                  'value': 'invalid_string_value',
                  'min': 'not_a_number',
                  'max': 'not_a_number',
                  'color': 'red_text',
                  'fontSize': 'medium',
                  'visible': 'yes',
                }),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('T2.3: $kind renders safely in compact boundary constraints (100x100)', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 100,
                height: 100,
                child: builder({}),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
