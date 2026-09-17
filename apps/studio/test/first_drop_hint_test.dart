// Verifies the first-time "drag a widget here" Canvas hint: shown on an
// empty canvas, gone after the first drop, and gone for good (not just
// while widgets exist) even if the user later deletes everything — part of
// the guided-first-dashboard onboarding push (see ROADMAP.md Milestone 10).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_library/widgets_library.dart';

import 'package:studio/main.dart';

const _hintText = 'Drag a widget from the palette to add it here';

Future<void> _bootIntoCanvas(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const ProviderScope(child: StudioApp()));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Canvas'));
  await tester.pumpAndSettle();
}

void main() {
  group('first-drop canvas hint', () {
    testWidgets('shown on an empty canvas that has never had a hint dismissal',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings.onboardingDone': true,
      });
      await _bootIntoCanvas(tester);

      expect(find.text(_hintText), findsOneWidget);
    });

    testWidgets('hidden once a widget is dropped, and does not come back',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings.onboardingDone': true,
      });
      await _bootIntoCanvas(tester);
      expect(find.text(_hintText), findsOneWidget);

      final source = find.text('Speedometer');
      final target = find.byType(DragTarget<Map<String, dynamic>>);
      await tester.drag(
          source, tester.getCenter(target) - tester.getCenter(source));
      await tester.pumpAndSettle();

      expect(find.byType(GaugeWidget), findsOneWidget);
      expect(find.text(_hintText), findsNothing);

      // Delete it again: canvas is empty once more, but the hint has done
      // its job and should stay dismissed.
      final gauge = find.byType(GaugeWidget);
      await tester.drag(gauge, const Offset(30, 15), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      expect(find.byType(GaugeWidget), findsNothing);
      expect(find.text(_hintText), findsNothing);
    });

    testWidgets('hidden when previously dismissed in a prior session',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'settings.onboardingDone': true,
        'settings.canvasHintDismissed': true,
      });
      await _bootIntoCanvas(tester);

      expect(find.text(_hintText), findsNothing);
    });
  });
}
