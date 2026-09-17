// Verifies the new rotation field (parallel to the X/Y position fields)
// actually rotates the widget and round-trips through the transform
// matrix correctly — not just that it doesn't crash.
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

  testWidgets('setting rotation to 45 degrees updates and round-trips',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();

    // Fresh launch lands on the Template gallery; switch to Canvas mode
    // to reach the palette, matching a real user's first action.
    await tester.tap(find.text('Canvas'));
    await tester.pumpAndSettle();

    final source = find.text('Speedometer');
    final target = find.byType(DragTarget<Map<String, dynamic>>);
    await tester.drag(
        source, tester.getCenter(target) - tester.getCenter(source));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(GaugeWidget), const Offset(30, 15),
        warnIfMissed: false);
    await tester.pumpAndSettle();

    // _PositionFields renders X, then Y, then the rotation field in that
    // order (see studio_inspector.dart) — the third TextFormField.
    final degreeField = find.byType(TextFormField).at(2);

    await tester.enterText(degreeField, '45');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Real verification: the rendered Transform actually carries the new
    // rotation (checked via the transform matrix's linear part, not just
    // that the text field shows "45").
    final transformFinder = find.ancestor(
      of: find.byType(GaugeWidget),
      matching: find.byType(Transform),
    );
    final transform = tester.widget<Transform>(transformFinder.first).transform;
    final angleDegrees = (transform.entry(1, 0)).abs() > 1e-6 ||
            (transform.entry(0, 0)).abs() > 1e-6
        ? (transform.entry(1, 0) / transform.entry(0, 0))
        : 0.0;
    // tan(45°) == 1: b/a should be ~1 for a pure 45° rotation.
    expect(angleDegrees, closeTo(1.0, 0.01));

    // Round-trip: the field should still read 45 after committing (not
    // drift due to a decode/encode mismatch).
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).at(2),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.controller.text, '45');
  });
}
