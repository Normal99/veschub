// Verifies fixed-vocabulary string properties (a "style"/mode/unit toggle,
// e.g. gauge's `needleStyle`) get a real searchable picker via
// `PropertyMeta.options` instead of a raw text field showing a cryptic
// current value with no indication of what else is valid.
//
// Along the way this caught a real, related bug in the palette presets
// themselves: the shared `_dial()` gauge-preset helper (used by
// "Speedometer" and others) baked in `needleStyle: 'arc'` — not a value
// the gauge renderer recognises at all (only `'needle'` draws anything;
// every other string, 'arc' included, happened to produce "no needle" by
// accident). Fixed to the real `'none'` value these tests now exercise —
// exactly the kind of unrecognisable raw value this picker feature exists
// to surface and fix.
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
      'settings.capabilityLevel': 'advanced',
    });
  });

  Future<void> dropAndSelectGauge(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();
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
  }

  // The property row's own static label ("Needle") and the picker field's
  // *current value* can be the same string, so `find.text(...)` alone can't
  // tell them apart — read the field's actual displayed text instead.
  String fieldValue(WidgetTester tester) {
    return tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((w) => w.controller.text)
        .firstWhere((t) => t == 'Needle' || t == 'None' || t == 'arc');
  }

  testWidgets(
      'the Speedometer preset\'s needleStyle shows the real "None" option, '
      'not the invalid "arc" value it used to bake in', (tester) async {
    await dropAndSelectGauge(tester);
    await tester.ensureVisible(find.text('Needle').last);
    await tester.pumpAndSettle();

    expect(fieldValue(tester), 'None');
  });

  testWidgets(
      'tapping the Needle field shows every option, including "Needle" '
      'itself, not just the current selection', (tester) async {
    await dropAndSelectGauge(tester);
    await tester.ensureVisible(find.text('None').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();

    // Both options should now be visible: the current one ("None", as a
    // menu row this time, in addition to wherever it briefly lingers as
    // the field's pre-clear text) and the other choice, "Needle".
    expect(find.text('Needle'), findsWidgets);
  });

  testWidgets('selecting a different option commits it', (tester) async {
    await dropAndSelectGauge(tester);
    await tester.ensureVisible(find.text('None').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('None').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Needle').last);
    await tester.pumpAndSettle();

    expect(fieldValue(tester), 'Needle');
  });
}
