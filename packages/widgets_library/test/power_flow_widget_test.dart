import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 60,
            child: PowerFlowWidget(properties: props),
          ),
        ),
      );

  testWidgets('discharging power shows the bolt icon and the value',
      (tester) async {
    await tester.pumpWidget(host({'power': 42, 'maxPower': 100}));
    await tester.pump();

    expect(find.byIcon(Icons.bolt), findsOneWidget);
    expect(find.byIcon(Icons.battery_charging_full), findsNothing);
    expect(find.text('42'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'regenerating (negative) power shows the charging icon and an '
      'absolute value', (tester) async {
    await tester.pumpWidget(host({'power': -15, 'maxPower': 100}));
    await tester.pump();

    expect(find.byIcon(Icons.battery_charging_full), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsNothing);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('the track keeps a visible border even at zero power',
      (tester) async {
    await tester.pumpWidget(host(const {}));
    await tester.pump();

    final containers = tester.widgetList<Container>(find.byType(Container));
    expect(
      containers.any((c) {
        final decoration = c.decoration;
        return decoration is BoxDecoration && decoration.border != null;
      }),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
