import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_storage/dashboard_storage.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late DashboardDatabase db;

  setUp(() {
    db = DashboardDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  test('save and load a dashboard round-trips', () async {
    const doc = DashboardDocument(
      name: 'Test board',
      canvas: CanvasSize(width: 800, height: 480),
      widgets: [
        WidgetInstance(
          id: 'g1',
          kind: 'gauge',
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'max': Binding.literal(value: 30000),
          },
        ),
      ],
    );

    final id = await db.saveDashboard('My board', doc);
    expect(id, greaterThan(0));

    final entry = await db.dashboardById(id);
    expect(entry, isNotNull);
    expect(entry!.name, 'My board');

    final decoded = db.decodeDocument(entry);
    expect(decoded.name, 'Test board');
    expect(decoded.widgets, hasLength(1));
    expect(decoded.widgets.first.kind, 'gauge');
    expect(decoded.widgets.first.properties['value'], isA<TelemetryBinding>());
  });

  test('recentDashboards orders by updatedAt desc', () async {
    final a = await db.saveDashboard(
      'A',
      const DashboardDocument(canvas: CanvasSize(width: 1, height: 1)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final b = await db.saveDashboard(
      'B',
      const DashboardDocument(canvas: CanvasSize(width: 1, height: 1)),
    );

    final recent = await db.recentDashboards();
    expect(recent.map((e) => e.name).toList(), ['B', 'A']);
    expect(recent.first.id, b);
    expect(recent.last.id, a);
  });

  test('updateDocument bumps updatedAt and replaces content', () async {
    final id = await db.saveDashboard(
      'orig',
      const DashboardDocument(canvas: CanvasSize(width: 1, height: 1)),
    );
    final before = await db.dashboardById(id);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    const updated = DashboardDocument(
      name: 'orig',
      canvas: CanvasSize(width: 2, height: 2),
    );
    final ok = await db.updateDocument(id, updated);
    expect(ok, isTrue);

    final after = await db.dashboardById(id);
    final decodedAfter = db.decodeDocument(after!);
    expect(decodedAfter.canvas.width, 2);
    expect(after.updatedAt.isAfter(before!.updatedAt), isTrue);
  });

  test('deleteDashboard removes the row', () async {
    final id = await db.saveDashboard(
      'gone',
      const DashboardDocument(canvas: CanvasSize(width: 1, height: 1)),
    );
    final n = await db.deleteDashboard(id);
    expect(n, 1);
    expect(await db.dashboardById(id), isNull);
  });
}
