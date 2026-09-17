// Regression test for a reported bug: dragging a numeric property's slider
// "doesn't change and doesn't save," and its companion text field "can't
// change the values properly and can't backspace." The slider itself
// wasn't broken — dragging always committed correctly. The text field was:
// Backspace inside it was being swallowed by the canvas-level
// delete-selected-widget shortcut (CallbackShortcuts consumes a matching
// key event the instant its activator matches, even when the bound
// callback is a guarded no-op while typing), so the keystroke never
// reached the field's own delete-character handling.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';

import 'package:studio/main.dart';
import 'package:studio/providers/editor_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
    });
  });

  Future<ProviderContainer> dropAndSelectGauge(WidgetTester tester) async {
    final container = ProviderContainer(overrides: [
      editorModeProvider.overrideWith((ref) => EditorMode.canvas),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const StudioApp()),
    );
    await tester.pumpAndSettle();

    final node = CanvasNode(
      id: 'test_gauge',
      transform: Matrix4.identity(),
      data: const WidgetInstance(
        id: 'test_gauge',
        kind: 'gauge',
        properties: {'tickCount': Binding.literal(value: 10)},
      ),
    );
    container.read(sceneModelProvider.notifier).add(node);
    container.read(selectionModelProvider.notifier).set('test_gauge');
    await tester.pumpAndSettle();

    final visualsHeader = find.text('Visuals');
    await tester.ensureVisible(visualsHeader);
    await tester.pumpAndSettle();
    await tester.tap(visualsHeader);
    await tester.pumpAndSettle();

    return container;
  }

  testWidgets('dragging the Ticks slider persists the new value',
      (tester) async {
    final container = await dropAndSelectGauge(tester);

    final slider =
        find.byWidgetPredicate((w) => w is Slider && w.min == 2 && w.max == 50);
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    expect(slider, findsOneWidget);

    await tester.drag(slider, const Offset(100, 0));
    await tester.pumpAndSettle();

    final widget = container.read(sceneModelProvider)['test_gauge']!.data
        as WidgetInstance;
    final tickCount = (widget.properties['tickCount'] as LiteralBinding).value;
    expect(tickCount, isNot(10));
  });

  testWidgets(
      'backspace inside the slider companion text field edits the text '
      'instead of being swallowed', (tester) async {
    final container = await dropAndSelectGauge(tester);

    final initialMatch = find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == '10');
    await tester.ensureVisible(initialMatch);
    await tester.pumpAndSettle();
    expect(initialMatch, findsOneWidget);

    // Capture by controller identity, not current text — the predicate
    // above only matches while the text is still exactly '10'.
    final controller = tester.widget<EditableText>(initialMatch).controller;
    final ticksField = find.byWidgetPredicate(
        (w) => w is EditableText && identical(w.controller, controller));

    await tester.tap(ticksField);
    await tester.pumpAndSettle();
    await tester.enterText(ticksField, '105');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // The widget must not have been deleted by the global shortcut.
    expect(container.read(sceneModelProvider)['test_gauge'], isNotNull);

    // And backspace must have actually removed a character.
    final edited = tester.widget<EditableText>(ticksField);
    expect(edited.controller.text, '10');
  });
}
