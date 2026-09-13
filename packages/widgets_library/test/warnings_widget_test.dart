import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 100,
            child: WarningsWidget(properties: props),
          ),
        ),
      );

  testWidgets('shows a text label under each icon by default', (tester) async {
    await tester.pumpWidget(host({
      'activeWarnings': 'battery:Low voltage,temp:Overheating',
    }));
    await tester.pump();

    expect(find.byIcon(Icons.battery_alert), findsOneWidget);
    expect(find.text('Low voltage'), findsOneWidget);
    expect(find.byIcon(Icons.thermostat), findsOneWidget);
    expect(find.text('Overheating'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showLabels false hides the text but keeps the icon and tooltip',
      (tester) async {
    await tester.pumpWidget(host({
      'activeWarnings': 'battery:Low voltage',
      'showLabels': false,
    }));
    await tester.pump();

    expect(find.byIcon(Icons.battery_alert), findsOneWidget);
    expect(find.text('Low voltage'), findsNothing);
    expect(find.byTooltip('Low voltage'), findsOneWidget);
  });

  testWidgets(
      'a warning with no explicit message falls back to its type as '
      'the label', (tester) async {
    await tester.pumpWidget(host({'activeWarnings': 'gps'}));
    await tester.pump();

    expect(find.byIcon(Icons.gps_off), findsOneWidget);
    expect(find.text('gps'), findsOneWidget);
  });

  testWidgets('no active warnings shows the OK state', (tester) async {
    await tester.pumpWidget(host(const {}));
    await tester.pump();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
