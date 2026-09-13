import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 150,
            child: MiniGaugeWidget(properties: props),
          ),
        ),
      );

  testWidgets('with no displayUnit set, shows the raw value and literal unit',
      (tester) async {
    await tester.pumpWidget(host({
      'value': 42,
      'min': 0,
      'max': 100,
      'unit': '°C',
    }));
    await tester.pump();
    expect(find.text('42'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
  });

  testWidgets('displayUnit converts value/min/max from sourceUnit together',
      (tester) async {
    await tester.pumpWidget(host({
      'value': 100,
      'min': 0,
      'max': 100,
      'sourceUnit': 'celsius',
      'displayUnit': 'fahrenheit',
    }));
    await tester.pump();
    // 100C -> 212F.
    expect(find.text('212'), findsOneWidget);
    expect(find.text('°F'), findsOneWidget);
  });

  testWidgets('displayUnit same as sourceUnit is a no-op', (tester) async {
    await tester.pumpWidget(host({
      'value': 50,
      'min': 0,
      'max': 100,
      'sourceUnit': 'celsius',
      'displayUnit': 'celsius',
    }));
    await tester.pump();
    expect(find.text('50'), findsOneWidget);
    expect(find.text('°C'), findsOneWidget);
  });
}
