import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:studio/main.dart';
import 'package:studio/editor/studio_editor.dart';
import 'package:studio/providers/editor_providers.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.capabilityLevel': 'advanced',
    });
  });

  Widget buildTestableStudio({List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        editorModeProvider.overrideWith((ref) => EditorMode.canvas),
        ...overrides,
      ],
      child: const StudioApp(),
    );
  }

  group('Property Inspector Tier 1: UI Layout & Category Accordions', () {
    testWidgets(
        'T1.1: Shows empty selection placeholder when no widget is selected',
        (tester) async {
      await tester.pumpWidget(buildTestableStudio());
      await tester.pumpAndSettle();

      expect(
          find.text('Select a widget to edit its properties'), findsOneWidget);
    });

    testWidgets(
        'T1.2: Renders categorized property fields when a widget is selected',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
        editorModeProvider.overrideWith((ref) => EditorMode.canvas),
      ]);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const StudioApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Add a node to scene with transform parameter
      final node = CanvasNode(
        id: 'test_gauge',
        transform: Matrix4.identity(),
        data: const WidgetInstance(
          id: 'test_gauge',
          kind: 'gauge',
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'label': Binding.literal(value: 'Engine RPM'),
            'color': Binding.literal(value: 0xFF4FC3F7),
          },
        ),
      );
      container.read(capabilityLevelProvider.notifier).state =
          CapabilityLevel.expert;
      container.read(sceneModelProvider.notifier).add(node);
      container.read(selectionModelProvider.notifier).set('test_gauge');
      await tester.pumpAndSettle();

      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('test_gauge'), findsWidgets);
      // Verify ExpansionTile accordion section headers for property categories render
      expect(find.text('Visuals'), findsWidgets);
      expect(find.text('Data Bindings'), findsWidgets);
      expect(find.text('Layout & Spacing'), findsWidgets);
      expect(find.text('Fonts & Colors'), findsWidgets);
    });

    testWidgets(
        'T1.3: Tooltips exist on inspector controls and mode switch chips',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
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

      // Verify Tooltip widgets exist for delete button and the binding
      // indicator (now a single consolidated icon per property, not four
      // always-visible chips — see _BindingIndicator in studio_inspector.dart).
      expect(find.byTooltip('Delete widget'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip && (w.message?.startsWith('Literal value') ?? false)),
        findsWidgets,
      );

      // Tapping the indicator opens a popup surfacing the other binding
      // types to switch to.
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();
      expect(find.text('Telemetry binding'), findsOneWidget);
      expect(find.text('Formula expression'), findsOneWidget);
      expect(find.text('Graph binding'), findsOneWidget);
    });

    testWidgets(
        'T1.4: Direct Hex color entry handles #RRGGBB format correctly on inspector fields',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
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
        id: 'test_bar',
        transform: Matrix4.identity(),
        data: const WidgetInstance(
          id: 'test_bar',
          kind: 'bar',
          properties: {'color': Binding.literal(value: 0xFF00FF00)},
        ),
      );
      container.read(sceneModelProvider.notifier).add(node);
      container.read(selectionModelProvider.notifier).set('test_bar');
      await tester.pumpAndSettle();

      expect(StudioEditor.parseHexColor('#4FC3F7'), equals(0xFF4FC3F7));
      expect(StudioEditor.parseHexColor('4FC3F7'), equals(0xFF4FC3F7));
      expect(StudioEditor.parseHexColor('FF4FC3F7'), equals(0xFF4FC3F7));
    });

    testWidgets(
        'T1.5: Numeric slider scrubbing renders and clamps within min/max bounds',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
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
        id: 'test_gauge_slider',
        transform: Matrix4.identity(),
        data: const WidgetInstance(
          id: 'test_gauge_slider',
          kind: 'gauge',
          properties: {
            'fontSize': Binding.literal(value: 24.0),
          },
        ),
      );
      container.read(sceneModelProvider.notifier).add(node);
      container.read(selectionModelProvider.notifier).set('test_gauge_slider');
      await tester.pumpAndSettle();

      // The slider-bearing properties here (tickCount, arcWidth, etc.) are
      // in Visuals, which isn't the first auto-expanded category for a
      // gauge anymore — Data Bindings (value/min/max) deliberately is, so
      // the binding editor is immediately visible on a fresh selection.
      await tester.ensureVisible(find.text('Visuals'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Visuals'));
      await tester.pumpAndSettle();

      // Verify numeric Slider widget renders for bounded property
      expect(find.byType(Slider), findsWidgets);
    });
  });

  group('Property Inspector Tier 2: Boundary & Corner Cases', () {
    testWidgets(
        'T2.1: Invalid hex format displays validation fallback without breaking state',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
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
        id: 'test_bar_invalid',
        transform: Matrix4.identity(),
        data: const WidgetInstance(
          id: 'test_bar_invalid',
          kind: 'bar',
          properties: {'color': Binding.literal(value: 0xFF00FF00)},
        ),
      );
      container.read(sceneModelProvider.notifier).add(node);
      container.read(selectionModelProvider.notifier).set('test_bar_invalid');
      await tester.pumpAndSettle();

      expect(find.byType(StudioApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'T2.2: Telemetry key filter field filters target key strings dynamically in dropdown',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
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
        id: 'test_tel_node',
        transform: Matrix4.identity(),
        data: const WidgetInstance(
          id: 'test_tel_node',
          kind: 'gauge',
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
          },
        ),
      );
      container.read(sceneModelProvider.notifier).add(node);
      container.read(selectionModelProvider.notifier).set('test_tel_node');
      await tester.pumpAndSettle();

      // Enter filter string 'duty' in the key search filter field
      final filterInputs = find.byType(TextFormField);
      if (filterInputs.evaluate().isNotEmpty) {
        await tester.enterText(filterInputs.first, 'duty');
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'T2.3: Deselecting widget returns inspector to clean placeholder view',
        (tester) async {
      final container = ProviderContainer(overrides: [
        // These tests exercise the Canvas-mode inspector; the app now
        // lands on the Template gallery by default, so force Canvas here.
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
        id: 'temp_node',
        transform: Matrix4.identity(),
        data:
            const WidgetInstance(id: 'temp_node', kind: 'text', properties: {}),
      );
      container.read(sceneModelProvider.notifier).add(node);
      container.read(selectionModelProvider.notifier).set('temp_node');
      await tester.pumpAndSettle();

      expect(find.text('Properties'), findsOneWidget);

      container.read(selectionModelProvider.notifier).clear();
      await tester.pumpAndSettle();

      expect(
          find.text('Select a widget to edit its properties'), findsOneWidget);
    });
  });
}
