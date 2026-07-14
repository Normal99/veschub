/// Riverpod providers for the studio editor.
///
/// Centralises the [SceneModel], [SelectionModel], [CommandStack], clipboard,
/// and the document being edited. The studio widgets consume these; mutations
/// flow through the command stack so every edit is undoable.
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_storage/dashboard_storage.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'settings_provider.dart';

/// Singleton drift database (opened lazily).
final dashboardDatabaseProvider = Provider<DashboardDatabase>((ref) {
  final db = DashboardDatabase();
  ref.onDispose(db.close);
  return db;
});

/// The scene model backing the canvas.
final sceneModelProvider = ChangeNotifierProvider<SceneModel>((ref) {
  return SceneModel();
});

/// The current selection.
final selectionModelProvider = ChangeNotifierProvider<SelectionModel>((ref) {
  return SelectionModel();
});

/// The undo/redo stack bound to the scene.
final commandStackProvider = ChangeNotifierProvider<CommandStack>((ref) {
  final scene = ref.watch(sceneModelProvider);
  return CommandStack(scene);
});

/// In-memory node clipboard.
final nodeClipboardProvider = Provider<NodeClipboard>((ref) {
  return NodeClipboard();
});

/// Fresh-id generator for pasted nodes.
final idGeneratorProvider = Provider<IdGenerator>((ref) {
  return IdGenerator(() => 'widget');
});

/// The active editor mode (Template/Canvas/Flow).
final editorModeProvider = StateProvider<EditorMode>((ref) {
  return EditorMode.canvas;
});

/// The active capability level (gates which props/handles are visible).
///
/// Seeded from the persisted [SettingsService] default on launch and rebuilds
/// reactively when the persisted level changes; the toolbar selector overrides
/// it for the session without persisting.
final capabilityLevelProvider = StateProvider<CapabilityLevel>((ref) {
  return ref.watch(settingsServiceProvider).capabilityLevel;
});

/// Whether the current document has unsaved changes.
final isDirtyProvider = StateProvider<bool>((ref) {
  return false;
});

/// The name of the dashboard being edited (for save).
final dashboardNameProvider = StateProvider<String>((ref) {
  return 'Untitled';
});

/// The database row id of the dashboard being edited (null = unsaved).
final dashboardIdProvider = StateProvider<int?>((ref) {
  return null;
});

/// Recent dashboards list (refreshable).
final recentDashboardsProvider =
    FutureProvider.autoDispose<List<Dashboard>>((ref) async {
  final db = ref.watch(dashboardDatabaseProvider);
  return db.recentDashboards();
});
