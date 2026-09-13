import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props, {double width = 300, double height = 220}) =>
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: PowerWidget(properties: props),
          ),
        ),
      );

  testWidgets(
      'the bar row does not overflow at the default drop size (regression: '
      'a margin-on-every-bar off-by-one overflowed by exactly one gap)',
      (tester) async {
    await tester.pumpWidget(host({
      'power': 0,
      'maxPower': 10000,
      'showBars': true,
      'label': 'Power',
      'fontSize': 28,
      'padding': 12,
    }));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the bar row does not overflow at a narrower width either (confirms '
      'the fix is not just tuned to exactly 300px)', (tester) async {
    await tester.pumpWidget(host(
      {
        'power': 500,
        'maxPower': 5000,
        'showBars': true,
        'fontSize': 20,
        'padding': 8,
      },
      width: 200,
      height: 140,
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
