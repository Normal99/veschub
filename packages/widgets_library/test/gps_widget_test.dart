import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 220,
            height: 120,
            child: GpsWidget(properties: props),
          ),
        ),
      );

  testWidgets('shows speed, altitude, and coordinates when all are bound',
      (tester) async {
    await tester.pumpWidget(host({
      'speed': 42,
      'altitude': 34,
      'lat': 52.52,
      'lon': 13.405,
      'unit': 'km/h',
    }));
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('km/h'), findsOneWidget);
    expect(find.text('Alt: 34 m'), findsOneWidget);
    expect(find.text('52.5200°N, 13.4050°E'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('south/west coordinates get the right hemisphere letters',
      (tester) async {
    await tester.pumpWidget(host({
      'lat': -33.87,
      'lon': -151.21,
      'speed': 0,
    }));
    await tester.pump();

    expect(find.text('33.8700°S, 151.2100°W'), findsOneWidget);
  });

  testWidgets('shows placeholders instead of crashing with nothing bound',
      (tester) async {
    await tester.pumpWidget(host(const {}));
    await tester.pump();

    expect(find.text('--'), findsOneWidget);
    expect(find.text('Alt: -- m'), findsOneWidget);
    expect(find.text('No GPS fix yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('showCoordinates false hides the lat/lon line', (tester) async {
    await tester.pumpWidget(host({
      'lat': 52.52,
      'lon': 13.405,
      'showCoordinates': false,
    }));
    await tester.pump();

    expect(find.textContaining('°N'), findsNothing);
  });
}
