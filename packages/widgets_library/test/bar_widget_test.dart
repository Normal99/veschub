import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 60,
            child: BarWidget(properties: props),
          ),
        ),
      );

  testWidgets('showValue overlays the formatted current value', (tester) async {
    await tester.pumpWidget(host({
      'value': 42,
      'min': 0,
      'max': 100,
      'showValue': true,
    }));
    await tester.pump();
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('showValue false renders no overlay text', (tester) async {
    await tester.pumpWidget(host({
      'value': 42,
      'min': 0,
      'max': 100,
      'showValue': false,
    }));
    await tester.pump();
    expect(find.text('42'), findsNothing);
  });

  testWidgets('gradient uses a LinearGradient instead of a flat colour fill',
      (tester) async {
    await tester.pumpWidget(host({
      'value': 50,
      'min': 0,
      'max': 100,
      'gradient': true,
      'color': 0xFFFF0000,
      'gradientColor': 0xFF0000FF,
    }));
    await tester.pump();

    final decoratedBoxes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>();
    final hasGradientFill = decoratedBoxes.any((d) =>
        d.gradient is LinearGradient &&
        (d.gradient as LinearGradient).colors.length == 2);
    expect(hasGradientFill, isTrue,
        reason: 'expected one fill container to use a 2-colour LinearGradient');
  });

  testWidgets(
      'barRadius controls the fill corner radius independently of borderRadius',
      (tester) async {
    await tester.pumpWidget(host({
      'value': 50,
      'min': 0,
      'max': 100,
      'borderRadius': 2,
      'barRadius': 20,
    }));
    await tester.pump();

    final decoratedBoxes = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((w) => w.decoration)
        .whereType<BoxDecoration>()
        .toList();
    final radii = decoratedBoxes
        .map((d) => (d.borderRadius as BorderRadius?)?.topLeft.x)
        .whereType<double>()
        .toSet();
    // Track uses borderRadius (2), fill uses barRadius (20) — both values
    // must appear among the painted decorations, not just one of them.
    expect(radii, containsAll([2.0, 20.0]));
  });
}
