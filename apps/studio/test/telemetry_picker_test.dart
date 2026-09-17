// Verifies the telemetry-binding key picker shows human-readable names
// (e.g. "Motor Speed (ERPM)") instead of only the raw VESC field name a
// beginner has no reason to recognise, offers every known key from a
// single searchable field (replacing a separate "Manual" mode toggle),
// and still accepts typing an arbitrary custom key (a VESC LispBM
// variable, etc.) directly.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:widgets_library/widgets_library.dart';

import 'package:studio/main.dart';
import 'package:studio/editor/studio_editor.dart';
import 'package:studio/providers/editor_providers.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
    });
  });

  Future<void> dropTextWidgetBoundToErpm(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
        properties: {'value': Binding.telemetry(key: 'erpm')},
      ),
    );
    container.read(sceneModelProvider.notifier).add(node);
    container.read(selectionModelProvider.notifier).set('test_text');
    await tester.pumpAndSettle();

    // 'value' lives in the Data Bindings category, which is now the first
    // (auto-expanded) one for any widget that has one — no tap needed.
  }

  ProviderContainer canvasContainer() => ProviderContainer(overrides: [
        editorModeProvider.overrideWith((ref) => EditorMode.canvas),
      ]);

  testWidgets(
      'a telemetry-bound value shows a human-readable name, not the raw '
      'VESC field name alone', (tester) async {
    final container = canvasContainer();
    await dropTextWidgetBoundToErpm(tester, container);

    expect(find.textContaining('Motor Speed (ERPM)'), findsOneWidget);
  });

  testWidgets(
      'tapping the field shows other known keys by their friendly names',
      (tester) async {
    final container = canvasContainer();
    await dropTextWidgetBoundToErpm(tester, container);

    await tester.tap(find.textContaining('Motor Speed (ERPM)').last);
    await tester.pumpAndSettle();

    // The options popup is a lazily-built, scrollable list capped at a
    // fixed height (see _OptionsList), so only checking an entry near the
    // top of TelemetryKey.all — this is about proving other keys are
    // offered at all, not about scrolling a popup.
    expect(find.textContaining('Duty Cycle'), findsOneWidget);
  });

  testWidgets('selecting a different known key commits its raw value',
      (tester) async {
    final container = canvasContainer();
    await dropTextWidgetBoundToErpm(tester, container);

    await tester.tap(find.textContaining('Motor Speed (ERPM)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Duty Cycle').last);
    await tester.pumpAndSettle();

    final widget =
        container.read(sceneModelProvider)['test_text']!.data as WidgetInstance;
    final binding = widget.properties['value'] as TelemetryBinding;
    expect(binding.key, 'duty');
  });

  testWidgets(
      'typing a custom key not in the known list and pressing Enter commits '
      'it directly, no separate manual mode needed', (tester) async {
    final container = canvasContainer();
    await dropTextWidgetBoundToErpm(tester, container);

    await tester.tap(find.textContaining('Motor Speed (ERPM)').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).last, 'my_custom_lispbm_var');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final widget =
        container.read(sceneModelProvider)['test_text']!.data as WidgetInstance;
    final binding = widget.properties['value'] as TelemetryBinding;
    expect(binding.key, 'my_custom_lispbm_var');
  });
}
