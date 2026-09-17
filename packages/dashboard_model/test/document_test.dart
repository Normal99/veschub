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

  group('DashboardMigrator', () {
    test('v1 document without description is upgraded to v2 with empty string',
        () {
      final v1 = <String, dynamic>{
        'version': 1,
        'name': 'Legacy board',
        'canvas': {'width': 800.0, 'height': 600.0},
      };
      final migrated = migrate(v1);
      expect(migrated['version'], 2);
      expect(migrated['description'], '');
      // Decoding the migrated map succeeds and yields the field.
      final doc = DashboardDocument.fromJson(migrated);
      expect(doc.description, '');
      expect(doc.name, 'Legacy board');
    });

    test('v2 document passes through unchanged aside from version stamping',
        () {
      final v2 = <String, dynamic>{
        'version': 2,
        'name': 'Modern',
        'description': 'A real description',
        'canvas': {'width': 100.0, 'height': 100.0},
      };
      final migrated = migrate(v2);
      expect(migrated['version'], 2);
      expect(migrated['description'], 'A real description');
    });

    test('unversioned document is treated as v1 and migrated', () {
      final migrated = migrate({'name': 'no version field'});
      expect(migrated['version'], kCurrentDocumentVersion);
      expect(migrated['description'], '');
    });
  });
}
