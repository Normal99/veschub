// Verifies dropping a new widget onto a spot already occupied by another
// widget nudges it to a nearby empty spot instead of stacking them exactly
// on top of each other — part of the "smart-default widget sizing/
// positioning when dropped on canvas" roadmap item (Milestone 10).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_library/widgets_library.dart';

import 'package:studio/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
    });
  });

  testWidgets(
      'dropping a second widget on top of the first lands it somewhere else',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Canvas'));
    await tester.pumpAndSettle();

    final target = find.byType(DragTarget<Map<String, dynamic>>);
    final dropSpot = tester.getCenter(target);
    final gaugeSource = find.text('Speedometer');

    // Drop the first gauge at the exact centre of the drop target.
    await tester.drag(gaugeSource, dropSpot - tester.getCenter(gaugeSource));
    await tester.pumpAndSettle();
    expect(find.byType(GaugeWidget), findsOneWidget);
    final firstRect = tester.getRect(find.byType(GaugeWidget));

    // Drop a second gauge at that exact same spot.
    await tester.drag(gaugeSource, dropSpot - tester.getCenter(gaugeSource));
    await tester.pumpAndSettle();
    expect(find.byType(GaugeWidget), findsNWidgets(2));

    // Their rects shouldn't overlap — the overlap avoidance nudged the
    // second gauge elsewhere instead of stacking it on the first.
    final allRects = find
        .byType(GaugeWidget)
        .evaluate()
        .map((e) => tester.getRect(find.byWidget(e.widget)))
        .toList();
    expect(allRects[0].overlaps(allRects[1]), isFalse);
    // The first gauge stays put; only the second one gets nudged.
    expect(allRects, contains(firstRect));
  });
}
