import 'package:test/test.dart';
import 'package:dashboard_model/dashboard_model.dart';

void main() {
  group('DashboardDocument serialization', () {
    test('round-trips through JSON', () {
      const doc = DashboardDocument(
        canvas: CanvasSize(width: 1280, height: 720),
        name: 'Test board',
        widgets: [
          WidgetInstance(
            id: 'w1',
            kind: 'gauge',
            z: 1,
            properties: {
              'max': Binding.literal(value: 30000),
              'value': Binding.telemetry(key: 'erpm'),
            },
            level: CapabilityLevel.advanced,
          ),
        ],
      );

      final json = doc.toJson();
      expect(json['version'], kCurrentDocumentVersion);
      expect(json['name'], 'Test board');

      final decoded = DashboardDocument.fromJson(json);
      expect(decoded.name, 'Test board');
      expect(decoded.widgets, hasLength(1));
      final w = decoded.widgets.single;
      expect(w.id, 'w1');
      expect(w.kind, 'gauge');
      expect(w.level, CapabilityLevel.advanced);
      expect(w.properties['value'], isA<TelemetryBinding>());
      expect((w.properties['value'] as TelemetryBinding).key, 'erpm');
      expect(w.properties['max'], isA<LiteralBinding>());
      expect((w.properties['max'] as LiteralBinding).value, 30000);
    });

    test('default transform is identity', () {
      const w = WidgetInstance(id: 'w', kind: 'text');
      expect(w.transform, [1, 0, 0, 1, 0, 0]);
    });

    test('migrator pins current version and rejects future versions', () {
      final migrated = migrate({'name': 'old'});
      expect(migrated['version'], kCurrentDocumentVersion);

      expect(
        () => migrate({'version': 999}),
        throwsStateError,
      );
    });
  });

  group('CapabilityLevel', () {
    test('includes respects ordering', () {
      expect(CapabilityLevel.expert.includes(CapabilityLevel.basic), isTrue);
      expect(CapabilityLevel.basic.includes(CapabilityLevel.expert), isFalse);
      expect(
        CapabilityLevel.advanced.includes(CapabilityLevel.advanced),
        isTrue,
      );
    });

    test('defaultEditorMode maps levels to modes', () {
      expect(CapabilityLevel.basic.defaultEditorMode, EditorMode.template);
      expect(CapabilityLevel.advanced.defaultEditorMode, EditorMode.canvas);
      expect(CapabilityLevel.expert.defaultEditorMode, EditorMode.flow);
    });
  });
}
