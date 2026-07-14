import 'dart:convert';
import 'dart:io';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

export 'tables.dart';

part 'dashboard_database.g.dart';

/// The veschub SQLite database (drift).
///
/// Stores serialized dashboard documents keyed by name; the studio writes here,
/// the dashboard runtime reads from here to load a board to render.
@DriftDatabase(tables: [Dashboards])
class DashboardDatabase extends _$DashboardDatabase {
  DashboardDatabase() : super(_open());
  DashboardDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  /// Lists all saved dashboards, most-recently-updated first.
  Future<List<Dashboard>> recentDashboards() =>
      (select(dashboards)..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

  /// Loads a single dashboard by id.
  Future<Dashboard?> dashboardById(int id) =>
      (select(dashboards)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts a new dashboard row, returning the id.
  Future<int> saveDashboard(String name, DashboardDocument doc) {
    final now = DateTime.now();
    return into(dashboards).insert(
      DashboardsCompanion.insert(
        name: name,
        documentJson: jsonEncode(doc.toJson()),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Updates an existing dashboard's document (and bumps updatedAt).
  Future<bool> updateDocument(int id, DashboardDocument doc) async {
    final affected =
        await (update(dashboards)..where((t) => t.id.equals(id))).write(
      DashboardsCompanion(
        documentJson: Value(jsonEncode(doc.toJson())),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return affected > 0;
  }

  /// Deletes a dashboard by id.
  Future<int> deleteDashboard(int id) =>
      (delete(dashboards)..where((t) => t.id.equals(id))).go();

  /// Decodes a [Dashboard] row's JSON into a migrated [DashboardDocument].
  DashboardDocument decodeDocument(Dashboard entry) {
    final raw = jsonDecode(entry.documentJson) as Map<String, dynamic>;
    final migrated = migrate(raw);
    return DashboardDocument.fromJson(migrated);
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'veschub.db'));
    return NativeDatabase(file);
  });
}
