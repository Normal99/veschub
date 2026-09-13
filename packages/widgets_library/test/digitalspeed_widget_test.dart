import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 150,
            child: DigitalSpeedWidget(properties: props),
          ),
        ),
      );

  testWidgets('with no displayUnit set, shows the raw value and literal unit',
      (tester) async {
    await tester.pumpWidget(host({
      'value': 42,
      'unit': 'km/h',
    }));
    await tester.pump();
    expect(find.text('42'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
  });

  testWidgets('displayUnit converts from sourceUnit and overrides the suffix',
      (tester) async {
    await tester.pumpWidget(host({
      'value': 100,
      'sourceUnit': 'kmh',
      'displayUnit': 'mph',
    }));
    await tester.pump();
    expect(find.text('62.1'), findsOneWidget);
    expect(find.text('mph'), findsOneWidget);
  });

  testWidgets('displayUnit same as sourceUnit is a no-op', (tester) async {
    await tester.pumpWidget(host({
      'value': 88,
      'sourceUnit': 'kmh',
      'displayUnit': 'kmh',
    }));
    await tester.pump();
    expect(find.text('88'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
  });
}
