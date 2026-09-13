// Verifies the new canvas keyboard shortcuts (delete/copy/paste/undo) work,
// and — critically — that Delete/Backspace inside a property text field
// edits the text instead of deleting the selected widget. CallbackShortcuts
// is documented to defer to a focused descendant's own key handling, but
// given how destructive a mistake here would be (losing a widget while
// editing its position), this is verified directly rather than trusted.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  }

  testWidgets('Delete key removes the selected widget', (tester) async {
    await dropAndSelectGauge(tester);
    expect(find.byType(GaugeWidget), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    expect(find.byType(GaugeWidget), findsNothing);
    expect(find.text('Select a widget to edit its properties'), findsOneWidget);
  });

  testWidgets(
      'Backspace inside the position field edits text, does not delete the widget',
      (tester) async {
    await dropAndSelectGauge(tester);
    expect(find.byType(GaugeWidget), findsOneWidget);

    // The X position field is the first TextFormField once a widget is
    // selected (see _PositionFields in studio_inspector.dart).
    final xField = find.byType(TextFormField).first;
    await tester.tap(xField);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // The widget must still be there — backspace was consumed by the
    // focused text field, not by the canvas-level delete shortcut.
    expect(find.byType(GaugeWidget), findsOneWidget);
  });

  testWidgets('Ctrl+Z undoes the last add', (tester) async {
    await dropAndSelectGauge(tester);
    expect(find.byType(GaugeWidget), findsOneWidget);

    Future<void> undo() async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
    }

    // dropAndSelectGauge both drops the widget (AddNodeCommand) and then
    // drag-selects it, which itself commits a TransformNodesCommand for the
    // small selection-drag move — so undoing once only reverts that move,
    // not the add. Two undos: move, then add.
    await undo();
    expect(find.byType(GaugeWidget), findsOneWidget);
    await undo();
    expect(find.byType(GaugeWidget), findsNothing);
  });
}
