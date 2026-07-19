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
import 'package:node_graph/node_graph.dart';
import 'package:settings/settings.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

import '../document_bridge.dart';

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
  final scene = ref.read(sceneModelProvider);
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
/// Seeded from the persisted [SettingsService] default on launch; the toolbar
/// selector overrides it for the session without persisting. Changing the
/// persisted default in Settings only takes effect on the next app launch.
final capabilityLevelProvider = StateProvider<CapabilityLevel>((ref) {
  return ref.watch(settingsServiceProvider).capabilityLevel;
});

/// Whether the current document has unsaved changes.
final isDirtyProvider = StateProvider<bool>((ref) {
  return false;
});

/// Visibility of the grid overlay on the editor canvas.
final gridVisibleProvider = StateProvider<bool>((ref) {
  return false;
});

/// The name of the dashboard being edited (for save).
final dashboardNameProvider = StateProvider<String>((ref) {
  return 'Untitled';
});

/// The description of the dashboard being edited (for save).
final dashboardDescriptionProvider = StateProvider<String>((ref) {
  return '';
});

/// The database row id of the dashboard being edited (null = unsaved).
final dashboardIdProvider = StateProvider<int?>((ref) {
  return null;
});

/// The canvas size of the dashboard being edited.
final canvasSizeProvider = StateProvider<CanvasSize>((ref) {
  return kDefaultCanvasSize;
});

/// The background colour (ARGB int) of the dashboard being edited.
final backgroundProvider = StateProvider<int>((ref) {
  return kDefaultBackground;
});

/// The accent colour (ARGB int) of the dashboard being edited.
final accentProvider = StateProvider<int>((ref) {
  return kDefaultAccent;
});

/// The flow graphs (Expert mode) of the dashboard being edited, stored as
/// opaque JSON keyed by graph id (mirrors [DashboardDocument.graphs]).
final flowGraphsProvider = StateProvider<Map<String, dynamic>>((ref) {
  return const {};
});

/// Recent dashboards list (refreshable).
final recentDashboardsProvider =
    FutureProvider.autoDispose<List<Dashboard>>((ref) async {
  final db = ref.watch(dashboardDatabaseProvider);
  return db.recentDashboards();
});

// ---------------------------------------------------------------------------
// Flow mode providers (declared here so the document-loading helper below can
// reach them without a circular import).
// ---------------------------------------------------------------------------

/// The active flow graph being edited.
final flowGraphProvider = StateProvider<FlowGraph>((ref) {
  return FlowGraph.empty('graph_1');
});

/// Node properties for the active graph: nodeId → propName → value.
final flowPropertiesProvider =
    StateProvider<Map<String, Map<String, dynamic>>>((ref) {
  return const {};
});

/// Currently selected node in the flow editor.
final selectedNodeProvider = StateProvider<String?>((ref) => null);

/// A mock telemetry store seeded with plausible values so the canvas preview
/// renders widgets with meaningful data instead of blanks.
final canvasPreviewTelemetryProvider = Provider<TelemetryStore>((ref) {
  final store = TelemetryStore();
  store.ingest({
    TelemetryKey.erpm: 12000,
    TelemetryKey.duty: 0.65,
    TelemetryKey.vIn: 50.2,
    TelemetryKey.tempMosfet: 42.0,
    TelemetryKey.tempMotor: 55.0,
    TelemetryKey.currentMotor: 18.5,
    TelemetryKey.currentInput: 12.3,
    TelemetryKey.fault: 0,
  });
  ref.onDispose(store.dispose);
  return store;
});

// ---------------------------------------------------------------------------
// Document loading helper (shared by the open-dialog and template-apply paths
// so they never drift on the provider-seeding contract).
// ---------------------------------------------------------------------------

/// Applies a loaded [DashboardDocument] to all editor providers: loads the
/// scene, seeds the canvas/theme/flow-graph state, clears the command stack,
/// and marks the editor clean. Pass [id] when loading a stored row and [name]
/// to override the document's name (e.g. with the row's display name).
void applyDocumentToEditor(
  WidgetRef ref, {
  required SceneModel scene,
  required DashboardDocument doc,
  int? id,
  String? name,
}) {
  final (canvas, bg, accent, graphs) = sceneFromDocument(scene, doc);
  ref.read(dashboardNameProvider.notifier).state = name ?? doc.name;
  ref.read(dashboardDescriptionProvider.notifier).state = doc.description;
  ref.read(dashboardIdProvider.notifier).state = id;
  ref.read(canvasSizeProvider.notifier).state = canvas;
  ref.read(backgroundProvider.notifier).state = bg;
  ref.read(accentProvider.notifier).state = accent;
  ref.read(flowGraphsProvider.notifier).state = graphs;
  if (graphs.isNotEmpty) {
    final firstGraph = graphs.values.first as Map<String, dynamic>;
    ref.read(flowGraphProvider.notifier).state = FlowGraph.fromJson(firstGraph);
    final props = firstGraph['properties'];
    ref.read(flowPropertiesProvider.notifier).state = props is Map
        ? Map<String, Map<String, dynamic>>.fromEntries(
            props.entries.map(
              (e) => MapEntry(
                e.key.toString(),
                Map<String, dynamic>.from(e.value as Map),
              ),
            ),
          )
        : const {};
  } else {
    ref.read(flowGraphProvider.notifier).state = FlowGraph.empty('graph_1');
    ref.read(flowPropertiesProvider.notifier).state = const {};
  }
  ref.read(commandStackProvider).clear();
  ref.read(isDirtyProvider.notifier).state = false;
}
