// Regression test for a reported bug: "moving the sliders they dont change
// and dont save themselves in the state they are slided too." The slider
// drag *did* commit correctly to the model the whole time — the canvas
// preview (which reactively watches sceneModelProvider) updated instantly.
// The bug was that _PropertiesInspector itself read the scene once
// (`ref.read`) instead of watching it, and — being a `const` widget — never
// got rebuilt by the parent's coarser top-level rebuild either. So every
// property edit landed in the model but the inspector kept showing
// whatever it last rendered for an unrelated reason (e.g. selection
// changing). A Slider has no local memory of its own dragged position, so
// it's the starkest way this staleness becomes visible: it looks like the
// drag simply doesn't do anything.
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
      'the inspector reflects a property change committed straight to the '
      'scene model, without the selection changing', (tester) async {
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

    final sliderBefore = tester.widget<Slider>(find
        .byWidgetPredicate((w) => w is Slider && w.min == 2 && w.max == 50));
    expect(sliderBefore.value, 10.0);

    // Commit a change to the SAME property directly through the scene
    // model — exactly what a Slider's onChanged does under the hood —
    // without touching selectionModelProvider at all.
    final current = container.read(sceneModelProvider)['test_gauge']!;
    final currentWidget = current.data as WidgetInstance;
    final updatedProps = Map<String, Binding>.from(currentWidget.properties);
    updatedProps['tickCount'] = const Binding.literal(value: 40);
    container.read(sceneModelProvider.notifier).upsert(
          current.copyWith(
            data: currentWidget.copyWith(properties: updatedProps),
          ),
        );
    await tester.pumpAndSettle();

    final sliderAfter = tester.widget<Slider>(find
        .byWidgetPredicate((w) => w is Slider && w.min == 2 && w.max == 50));
    expect(sliderAfter.value, 40.0);
  });
}
