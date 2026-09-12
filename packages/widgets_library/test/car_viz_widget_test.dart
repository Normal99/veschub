import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('CarVizWidget Tier 1: Rendering & Feature Coverage', () {
    testWidgets('T1.1: CarVizWidget renders cleanly with default empty properties map ({})', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CarVizWidget(properties: {}),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.2: CarVizWidget renders doors left and right when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CarVizWidget(
                properties: {
                  'doorLeft': true,
                  'doorRight': true,
                  'color': 0xFFFFFFFF,
                  'accent': 0xFFFF9800,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.3: CarVizWidget renders proximity ring and text labels with custom fontSize', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 350,
              height: 350,
              child: CarVizWidget(
                properties: {
                  'showRing': true,
                  'showLabels': true,
                  'label': 'Vehicle Proximity',
                  'fontSize': 18.0,
                  'accent': 0xFF4488FF,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(find.text('Vehicle Proximity'), findsOneWidget);
      // 'Front' / 'Rear' labels are painted on canvas (TextPainter), not Flutter Text widgets
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T1.4: CarVizWidget renders lane warnings and car ahead visualization', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: CarVizWidget(
                properties: {
                  'laneLeft': true,
                  'laneRight': true,
                  'carAhead': true,
                  'color': 0xFFFFFFFF,
                  'accent': 0xFF0288D1,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CarVizWidget Tier 2: Boundary & Resiliency Cases', () {
    testWidgets('T2.1: CarVizWidget handles extreme fontSize values safely without overflow crash', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CarVizWidget(
                properties: {
                  'label': 'Proximity Warning',
                  'fontSize': 72.0,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(find.text('Proximity Warning'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.2: CarVizWidget handles invalid property types gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CarVizWidget(
                properties: {
                  'doorLeft': 'true', // string instead of bool
                  'doorRight': 1, // int instead of bool
                  'showRing': 'invalid',
                  'fontSize': 'huge', // string instead of double
                  'color': 'not_a_color',
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.3: CarVizWidget handles explicit null values in resolved properties map', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CarVizWidget(
                properties: {
                  'color': null,
                  'accent': null,
                  'doorLeft': null,
                  'doorRight': null,
                  'showRing': null,
                  'showLabels': null,
                  'label': null,
                  'fontSize': null,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('T2.4: CarVizWidget renders safely in tight boundary dimensions (50x50)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 50,
              height: 50,
              child: CarVizWidget(
                properties: {
                  'showRing': true,
                  'doorLeft': true,
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CarVizWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
