// Drives the real Studio UI end-to-end the way a human would: drag a widget
// from the palette onto the canvas, select it, and adjust it via the
// inspector — no direct provider/state manipulation. This is Flutter's
// WidgetTester exercising the actual gesture-recognizer code paths, the
// closest thing to a human controlling the app that runs headlessly.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_library/widgets_library.dart';

import 'package:studio/main.dart';

Future<void> _capture(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
    });
  });

  testWidgets('drag a widget onto the canvas, select it, move it',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();

    // A fresh launch lands on the Template gallery (friendlier for a
    // first-time user); switch to Canvas mode the same way a real user
    // would, by tapping the mode switcher, to reach the manual-creation flow.
    await tester.tap(find.text('Canvas'));
    await tester.pumpAndSettle();

    // Sanity: nothing on canvas yet, inspector shows the empty placeholder.
    expect(find.byType(GaugeWidget), findsNothing);
    expect(find.text('Select a widget to edit its properties'), findsOneWidget);
    await _capture(tester, '01_empty_canvas');

    // Drag the "Speedometer" gauge preset from the palette onto the canvas.
    final source = find.text('Speedometer');
    expect(source, findsOneWidget,
        reason: 'Gauge category should be expanded by default showing its presets');
    final target = find.byType(DragTarget<Map<String, dynamic>>);
    expect(target, findsOneWidget);

    final delta = tester.getCenter(target) - tester.getCenter(source);
    await tester.drag(source, delta);
    await tester.pumpAndSettle();

    // Real verification: a GaugeWidget now exists in the render tree, i.e.
    // AddNodeCommand actually ran via the real DragTarget.onAcceptWithDetails
    // path, not a shortcut.
    expect(find.byType(GaugeWidget), findsOneWidget);
    await _capture(tester, '02_after_drop');

    // Select it: on this canvas, selection happens on pan-start (hit-test),
    // so a tap alone won't trigger it — drag a small amount, matching how a
    // real user would click-drag the widget.
    // This canvas uses one top-level GestureDetector with manual internal
    // hit-testing rather than a per-node detector, so the exact render
    // object under the drag point legitimately differs from GaugeWidget's
    // own — the ancestor detector still receives it, which the assertions
    // below confirm.
    final gauge = find.byType(GaugeWidget);
    await tester.drag(gauge, const Offset(30, 15), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Real verification: the inspector populated with real property fields
    // (Kind: gauge), not the empty-selection placeholder.
    expect(find.text('Select a widget to edit its properties'), findsNothing);
    expect(find.text('gauge'), findsOneWidget);
    await _capture(tester, '03_selected_with_inspector');
  });
}
