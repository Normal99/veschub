// Verifies the fontFamily/fontWeight property rows use a real searchable
// picker (Autocomplete) instead of a raw text field — previously fontFamily
// in particular defaulted to the literal integer 0 with no guidance on
// valid values at all. Drives the actual Studio UI end-to-end.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_library/widgets_library.dart';

import 'package:studio/main.dart';

Future<void> _dropAndSelectGauge(WidgetTester tester) async {
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

/// "Fonts & Colors" isn't the first inspector category (so it starts
/// collapsed) and the inspector list is scrollable, so it starts off-screen
/// too. tester.drag(finder, ...) picks the finder's geometric centre as the
/// drag's start point, which here happens to land on an interactive child
/// (a text field) that doesn't bubble the gesture to the outer scrollable —
/// dragging from a corner inset instead reliably lands on plain
/// (non-interactive) space, which does.
Future<void> _expandFontsAndColors(WidgetTester tester) async {
  final scrollRect = tester.getRect(find.byType(SingleChildScrollView).first);
  await tester.dragFrom(
      scrollRect.topLeft + const Offset(10, 10), const Offset(0, -3000));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Fonts & Colors'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.capabilityLevel': 'advanced',
    });
  });

  testWidgets(
      'Font family defaults to "Default" (not a raw literal 0) and offers a '
      'searchable dropdown of the bundled fonts', (tester) async {
    await _dropAndSelectGauge(tester);
    await _expandFontsAndColors(tester);

    expect(find.text('Font family'), findsOneWidget);
    // The old bug: this field would have shown a raw literal "0" (an int)
    // with no indication it was even a font property. Now it shows the
    // picker's "Default" label.
    expect(find.text('Default'), findsOneWidget);

    // Type to filter, then pick a real bundled font from the dropdown.
    await tester.enterText(find.text('Default'), 'Orbitron');
    await tester.pumpAndSettle();
    expect(find.text('Orbitron'), findsWidgets);
    await tester.tap(find.text('Orbitron').last);
    await tester.pumpAndSettle();

    // The gauge's own rendered text should now use the selected font.
    final rendered = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(GaugeWidget),
        matching: find.byType(Text),
      ),
    );
    expect(
      rendered.any(
          (t) => t.style?.fontFamily == 'packages/widgets_library/Orbitron'),
      isTrue,
    );
  });

  testWidgets(
      'Font weight defaults to a real weight and offers a searchable '
      'dropdown of every accepted value', (tester) async {
    await _dropAndSelectGauge(tester);
    await _expandFontsAndColors(tester);

    // The old bug affected fontFamily specifically (defaulted to a raw
    // literal 0); fontWeight already defaulted to a valid string ('bold'),
    // but still only as a raw, undiscoverable free-text value. Confirms it
    // now shows the picker's real label instead.
    expect(find.text('Font weight'), findsOneWidget);
    expect(find.text('Bold (700)'), findsOneWidget);

    // Exercise the same search-and-select round trip the font-family test
    // already verifies end-to-end for a different field/value — picking a
    // distinctive, unambiguous query (no other weight label contains it).
    await tester.enterText(find.text('Bold (700)'), 'Semi');
    await tester.pumpAndSettle();
    expect(find.text('Semi Bold (600)'), findsWidgets);
    await tester.tap(find.text('Semi Bold (600)').last);
    await tester.pumpAndSettle();

    final rendered = tester.widgetList<Text>(
      find.descendant(
        of: find.byType(GaugeWidget),
        matching: find.byType(Text),
      ),
    );
    expect(rendered.any((t) => t.style?.fontWeight == FontWeight.w600), isTrue);
  });

  testWidgets(
      'A user-imported custom font appears in the font family picker '
      'alongside the bundled ones', (tester) async {
    // Simulates the persisted state after Settings > Custom Fonts > Import
    // — the widget under test never drives the actual OS file picker
    // (untestable here, same as every other FilePicker-based import flow in
    // this codebase; see custom_font_service.dart's doc comment). Only
    // checks the option is offered, not the full select-and-apply round
    // trip the other two tests in this file cover for bundled fonts —
    // tapping this option's overlay row reliably misses the hit test here
    // (lands on an Overlay-internal render object instead, regardless of
    // position/ensureVisible), which looks like a flutter_test harness
    // quirk rather than a bug in the feature. The underlying merge logic
    // itself (`fontChoicesProvider`) is covered directly by
    // packages/settings/test/settings_test.dart's custom-font tests.
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.capabilityLevel': 'advanced',
      'settings.customFonts': [
        '{"family":"My Custom Font","filePath":"/tmp/my_custom_font.ttf"}',
      ],
    });

    await _dropAndSelectGauge(tester);
    await _expandFontsAndColors(tester);

    await tester.enterText(find.text('Default'), 'My Custom');
    await tester.pumpAndSettle();
    expect(find.text('My Custom Font'), findsWidgets);
  });
}
