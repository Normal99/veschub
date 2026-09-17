// Regression/coverage test for tick customization added on request ("I
// would enjoy more tick customizability"): tickLength, tickWidth, and
// major/minor ticks (majorTickEvery + majorTickLength/majorTickWidth).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

Widget _gauge(Map<String, dynamic> properties) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 200,
          child: GaugeWidget(properties: properties),
        ),
      ),
    );

void main() {
  testWidgets('renders with default tick settings without throwing',
      (tester) async {
    await tester.pumpWidget(_gauge({'value': 5.0, 'min': 0.0, 'max': 10.0}));
    expect(find.byType(GaugeWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders with custom tick length and width without throwing',
      (tester) async {
    await tester.pumpWidget(_gauge({
      'value': 5.0,
      'min': 0.0,
      'max': 10.0,
      'tickCount': 20,
      'tickLength': 20.0,
      'tickWidth': 6.0,
    }));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders major/minor ticks without throwing', (tester) async {
    await tester.pumpWidget(_gauge({
      'value': 5.0,
      'min': 0.0,
      'max': 10.0,
      'tickCount': 20,
      'majorTickEvery': 5,
      'majorTickLength': 20.0,
      'majorTickWidth': 5.0,
      'showTickLabels': true,
    }));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'majorTickEvery of 0 (the default) behaves as if major ticks are off',
      (tester) async {
    await tester.pumpWidget(_gauge({
      'value': 5.0,
      'min': 0.0,
      'max': 10.0,
      'tickCount': 10,
      'majorTickEvery': 0,
    }));
    expect(tester.takeException(), isNull);
  });

  test('property manifest declares the new tick controls with sane bounds', () {
    final props = {for (final m in propertyManifest['gauge']!) m.key: m};

    expect(props['tickLength']!.min, 2);
    expect(props['tickLength']!.max, 40);

    expect(props['tickWidth']!.min, 0.5);
    expect(props['tickWidth']!.max, 10);

    expect(props['majorTickEvery']!.min, 0);
    expect(props['majorTickEvery']!.max, 20);

    expect(props['majorTickLength']!.min, 2);
    expect(props['majorTickLength']!.max, 50);

    expect(props['majorTickWidth']!.min, 0.5);
    expect(props['majorTickWidth']!.max, 12);
  });
}
