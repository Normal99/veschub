// Regression test for a reported bug: typing a space into a text property
// field would get silently dropped, because _LiteralEditor used to commit
// on every keystroke and round-trip through didUpdateWidget mid-typing.
import 'package:flutter/material.dart';
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

  testWidgets(
      'typing a value with an embedded space keeps the space once committed',
      (tester) async {
    final container = ProviderContainer(overrides: [
      editorModeProvider.overrideWith((ref) => EditorMode.canvas),
    ]);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const StudioApp(),
      ),
    );
    await tester.pumpAndSettle();

    final node = CanvasNode(
      id: 'test_text',
      transform: Matrix4.identity(),
      data: const WidgetInstance(
        id: 'test_text',
        kind: 'text',
        properties: {'label': Binding.literal(value: 'Speed')},
      ),
    );
    container.read(sceneModelProvider.notifier).add(node);
    container.read(selectionModelProvider.notifier).set('test_text');
    await tester.pumpAndSettle();

    // 'label' is in Visuals, which isn't the first auto-expanded category
    // for a text widget anymore — Data Bindings (value) deliberately is.
    // The inspector panel scrolls, so the header may start off-screen.
    final visualsHeader = find.text('Visuals');
    await tester.ensureVisible(visualsHeader);
    await tester.pumpAndSettle();
    await tester.tap(visualsHeader);
    await tester.pumpAndSettle();

    final initialMatch = find.byWidgetPredicate(
        (w) => w is EditableText && w.controller.text == 'Speed');
    await tester.ensureVisible(initialMatch);
    await tester.pumpAndSettle();
    expect(initialMatch, findsOneWidget);

    // Capture the field by its controller's identity rather than its
    // current text: the finder above only matches while the text is still
    // exactly 'Speed', which stops being true after the first keystroke.
    final controller = tester.widget<EditableText>(initialMatch).controller;
    final labelField = find.byWidgetPredicate(
        (w) => w is EditableText && identical(w.controller, controller));

    // Simulate real, incremental typing rather than one enterText call —
    // this is what actually exercises the per-keystroke round-trip that
    // was silently dropping the space.
    for (final partial in ['Speed ', 'Speed R', 'Speed Rea', 'Speed Read']) {
      await tester.enterText(labelField, partial);
      await tester.pump();
    }

    // Commit by submitting (matches how a real user finishes editing by
    // pressing enter).
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final widget =
        container.read(sceneModelProvider)['test_text']!.data as WidgetInstance;
    final label = (widget.properties['label'] as LiteralBinding).value;
    expect(label, 'Speed Read');

    // Also verify the blur path (the actual fix): type more, then move
    // focus elsewhere without submitting, and confirm it still commits
    // instead of silently reverting like the pre-fix per-keystroke commit
    // + didUpdateWidget round-trip used to.
    await tester.enterText(labelField, 'Speed Read Again');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    final widget2 =
        container.read(sceneModelProvider)['test_text']!.data as WidgetInstance;
    final label2 = (widget2.properties['label'] as LiteralBinding).value;
    expect(label2, 'Speed Read Again');
  });
}
