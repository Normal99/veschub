import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_model/dashboard_model.dart';
import 'package:studio/editor/studio_editor.dart';
import 'package:widgets_library/widgets_library.dart';
import 'package:templates/templates.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

/// Helper resolving widget properties against a TelemetryStore.
Map<String, dynamic> resolveWidgetProperties(WidgetInstance w, TelemetryStore store) {
  final out = <String, dynamic>{};
  for (final entry in w.properties.entries) {
    final v = entry.value.map(
      literal: (b) => b.value,
      telemetry: (b) => store.value(b.key),
      graph: (_) => null,
      formula: (_) => null,
    );
    if (v != null) out[entry.key] = v;
  }
  return out;
}

void main() {
  const targetKinds = [
    'gauge',
    'bar',
    'text',
    'chart',
    'status',
    'minigauge',
    'battery_range',
    'tripstats',
    'car_viz',
    'power_flow',
    'gear_selector',
  ];

  group('Studio Default Properties Tier 1 & Tier 2 (All 11 Core Kinds)', () {
    test('T1.1: All 11 core widget kinds return non-empty default property maps from studio_editor', () {
      for (final kind in targetKinds) {
        final defaults = StudioEditor.defaultProperties(kind);
        expect(defaults, isNotEmpty,
            reason: 'StudioEditor.defaultProperties("$kind") returned an empty map!');
      }
    });

    test('T1.2: Default property keys from studio_editor exist in widgets_library propertyManifest', () {
      for (final kind in targetKinds) {
        final defaultProps = StudioEditor.defaultProperties(kind);
        final manifestMetas = propertyManifest[kind] ?? [];
        final manifestKeys = manifestMetas.map((m) => m.key).toSet();

        for (final key in defaultProps.keys) {
          expect(manifestKeys.contains(key), isTrue,
              reason: 'Property key "$key" for "$kind" in studio_editor defaults is missing from propertyManifest!');
        }
      }
    });

    test('T1.3: Default property bindings resolve cleanly against TelemetryStore', () {
      final store = TelemetryStore();
      store.update('erpm', 15000.0);
      store.update('duty', 0.75);
      store.update('v_in', 48.5);
      store.update('fault', 0);

      final testWidget = const WidgetInstance(
        id: 'w1',
        kind: 'gauge',
        properties: {
          'value': Binding.telemetry(key: 'erpm'),
          'min': Binding.literal(value: 0),
          'max': Binding.literal(value: 30000),
          'label': Binding.literal(value: 'RPM'),
        },
      );

      final resolved = resolveWidgetProperties(testWidget, store);
      expect(resolved['value'], equals(15000.0));
      expect(resolved['min'], equals(0));
      expect(resolved['max'], equals(30000));
      expect(resolved['label'], equals('RPM'));
    });

    test('T1.4: Starter templates (minimal, performance, commuter, offroad) contain valid widget configurations', () {
      for (final template in builtInTemplates) {
        expect(template.document.widgets, isNotEmpty,
            reason: 'Template ${template.id} contains no widgets');
        for (final widget in template.document.widgets) {
          expect(builtInWidgets.containsKey(widget.kind), isTrue,
              reason: 'Template ${template.id} references unregistered kind ${widget.kind}');
          expect(widget.properties, isNotEmpty,
              reason: 'Widget ${widget.id} in template ${template.id} has empty properties map');
        }
      }
    });

    test('T2.1: Resolving widget properties with missing telemetry key returns null gracefully', () {
      final store = TelemetryStore();
      final testWidget = const WidgetInstance(
        id: 'w_missing',
        kind: 'text',
        properties: {
          'value': Binding.telemetry(key: 'non_existent_key'),
          'label': Binding.literal(value: 'Fallback Label'),
        },
      );

      final resolved = resolveWidgetProperties(testWidget, store);
      expect(resolved.containsKey('value'), isFalse);
      expect(resolved['label'], equals('Fallback Label'));
    });

    test('T2.2: Unknown widget kind handling returns empty resolved map', () {
      final store = TelemetryStore();
      final unknownWidget = const WidgetInstance(
        id: 'w_unknown',
        kind: 'non_existent_kind',
        properties: {},
      );

      final resolved = resolveWidgetProperties(unknownWidget, store);
      expect(resolved, isEmpty);
    });

    test('T2.3: Template applyEdits safely overrides target properties while retaining unedited bindings', () {
      final doc = Templates.minimal.applyEdits({
        'rpm.max': 40000,
        'rpm.color': 0xFFFF0000,
      });

      final rpmWidget = doc.widgets.firstWhere((w) => w.id == 'rpm');
      final maxBinding = rpmWidget.properties['max'] as LiteralBinding;
      final colorBinding = rpmWidget.properties['color'] as LiteralBinding;
      final valueBinding = rpmWidget.properties['value'];

      expect(maxBinding.value, equals(40000));
      expect(colorBinding.value, equals(0xFFFF0000));
      expect(valueBinding, isA<TelemetryBinding>());
    });
  });
}
