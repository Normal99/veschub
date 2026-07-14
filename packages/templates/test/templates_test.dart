import 'package:dashboard_model/dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:templates/templates.dart';

void main() {
  group('builtInTemplates', () {
    test('has 4 templates', () {
      expect(builtInTemplates, hasLength(4));
      expect(
        builtInTemplates.map((t) => t.id).toList(),
        ['minimal', 'performance', 'commuter', 'offroad'],
      );
    });

    test('all templates are Basic level', () {
      for (final t in builtInTemplates) {
        expect(
          t.level,
          CapabilityLevel.basic,
          reason: '${t.id} should be basic',
        );
      }
    });

    test('every knob targets an existing widget', () {
      for (final t in builtInTemplates) {
        final widgetIds = t.document.widgets.map((w) => w.id).toSet();
        for (final knob in t.knobs) {
          expect(
            widgetIds.contains(knob.widgetId),
            isTrue,
            reason:
                '${t.id}: knob ${knob.label} targets missing widget ${knob.widgetId}',
          );
        }
      }
    });

    test('every widget kind is a registered built-in', () {
      const knownKinds = {
        'gauge',
        'bar',
        'text',
        'chart',
        'status',
        'image',
        'web',
      };
      for (final t in builtInTemplates) {
        for (final w in t.document.widgets) {
          expect(
            knownKinds.contains(w.kind),
            isTrue,
            reason: '${t.id}: unknown widget kind ${w.kind}',
          );
        }
      }
    });
  });

  group('DashboardTemplate.applyEdits', () {
    test('applies a knob edit as a literal binding', () {
      final doc = Templates.minimal.applyEdits({
        'rpm.max': 45000,
        'rpm.color': 0xFFFF0000,
      });
      final w = doc.widgets.singleWhere((w) => w.id == 'rpm');
      final max = w.properties['max']!;
      expect(max, isA<LiteralBinding>());
      expect((max as LiteralBinding).value, 45000);
      final color = w.properties['color']!;
      expect((color as LiteralBinding).value, 0xFFFF0000);
    });

    test('preserves telemetry bindings on unedited properties', () {
      final doc = Templates.minimal.applyEdits({'rpm.max': 50000});
      final w = doc.widgets.singleWhere((w) => w.id == 'rpm');
      expect(w.properties['value'], isA<TelemetryBinding>());
    });

    test('ignores edits for non-existent widgets', () {
      final doc = Templates.minimal.applyEdits({'nonexistent.x': 1});
      expect(doc.widgets.first.id, 'rpm');
    });
  });
}
