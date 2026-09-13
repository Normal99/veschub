/// The studio editor screen: toolbar + palette + canvas + properties inspector.
///
/// This is the Phase 3 "editor that finally works" — drag-drop widgets from
/// the palette onto the [EditorCanvas], move/snap them with alignment guides,
/// edit bound properties in the inspector, and save/load to drift.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paint_dsl/paint_dsl.dart';
import 'package:node_graph/node_graph.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:settings/settings.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';

import '../document_bridge.dart';
import '../providers/editor_providers.dart';
import '../widgets/simple_color_picker.dart';
import 'flow_mode.dart';
import 'template_mode.dart';
import 'layer_panel.dart';
import 'keyboard_shortcuts.dart';

part 'studio_palette.dart';
part 'studio_canvas_area.dart';
part 'studio_inspector.dart';

enum _MenuAction { newDashboard, open, export, import, settings, toggleLayers }

/// A labeled row for the toolbar's overflow menu — an icon plus its name,
/// so the less-frequent actions (new/open/export/import/settings/layers)
/// don't have to be guessed from a bare icon.
class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MenuRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

/// A starter paint program for newly dropped `paint` widgets: a fixed track
/// circle with a filled circle whose radius is driven by the `$r` variable.
const PaintProgram _samplePaintProgram = PaintProgram(ops: [
  ClearOp(color: 0xFF101010),
  BrushOp(color: 0xFF444444, style: PaintFill.stroke, strokeWidth: 2),
  CircleOp(cx: 100, cy: 100, r: 90),
  BrushOp(color: 0xFF4CAF50, style: PaintFill.fill),
  CircleOp(cx: 100, cy: 100, r: '\$r'),
  BrushOp(color: 0xFFFFFFFF, style: PaintFill.stroke, strokeWidth: 1),
  LineOp(x1: 100, y1: 100, x2: 100, y2: 10),
]);

class StudioEditor extends ConsumerWidget {
  const StudioEditor({super.key});

  static Map<String, Binding> defaultProperties(String kind) =>
      _CanvasAreaState.defaultProperties(kind);

  static int? parseHexColor(String input) =>
      _LiteralEditorState.parseHexColor(input);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(editorModeProvider);
    final commands = ref.watch(commandStackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veschub Studio'),
        actions: [
          // Only the highest-frequency actions get a bare icon button — the
          // rest (new/open/export/import/settings/layers) are one tap away
          // in the labeled overflow menu below, rather than seven
          // indistinguishable icons in a row.
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: commands.canUndo ? commands.undo : null,
            tooltip: commands.undoLabel ?? 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: commands.canRedo ? commands.redo : null,
            tooltip: commands.redoLabel ?? 'Redo',
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(context, ref),
            tooltip: 'Save',
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: 'More',
            onSelected: (action) => switch (action) {
              _MenuAction.newDashboard => _newDashboard(context, ref),
              _MenuAction.open => _showOpenDialog(context, ref),
              _MenuAction.export => _exportJson(context, ref),
              _MenuAction.import => _importJson(context, ref),
              _MenuAction.settings =>
                Navigator.of(context).pushNamed('/settings'),
              _MenuAction.toggleLayers => ref
                  .read(layersVisibleProvider.notifier)
                  .state = !ref.read(layersVisibleProvider),
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _MenuAction.newDashboard,
                child: _MenuRow(icon: Icons.note_add, label: 'New dashboard'),
              ),
              const PopupMenuItem(
                value: _MenuAction.open,
                child: _MenuRow(icon: Icons.folder_open, label: 'Open'),
              ),
              const PopupMenuItem(
                value: _MenuAction.export,
                child: _MenuRow(
                    icon: Icons.download, label: 'Export as .veschub.json'),
              ),
              const PopupMenuItem(
                value: _MenuAction.import,
                child: _MenuRow(
                    icon: Icons.upload_file, label: 'Import .veschub.json'),
              ),
              const PopupMenuItem(
                value: _MenuAction.settings,
                child: _MenuRow(icon: Icons.settings, label: 'Settings'),
              ),
              PopupMenuItem(
                value: _MenuAction.toggleLayers,
                child: _MenuRow(
                  icon: ref.watch(layersVisibleProvider)
                      ? Icons.unfold_less
                      : Icons.unfold_more,
                  label: ref.watch(layersVisibleProvider)
                      ? 'Shrink layer list'
                      : 'Expand layer list',
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SegmentedButton<EditorMode>(
                  segments: const [
                    ButtonSegment(
                        value: EditorMode.template, label: Text('Template')),
                    ButtonSegment(
                        value: EditorMode.canvas, label: Text('Canvas')),
                    ButtonSegment(value: EditorMode.flow, label: Text('Flow')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (s) =>
                      ref.read(editorModeProvider.notifier).state = s.first,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
      body: switch (mode) {
        EditorMode.template => const TemplateMode(),
        EditorMode.canvas => CanvasKeyboardShortcuts(
            child: Row(
              children: [
                const _WidgetPalette(),
                Expanded(child: _CanvasArea()),
                // Layers and properties are stacked in one column, always
                // visible together — SimHub's Dash Studio keeps its component
                // list permanently visible above the property grid rather
                // than making them swap places, so you never lose sight of
                // the layer hierarchy while editing a property.
                SizedBox(
                  width: 280,
                  child: Column(
                    children: [
                      SizedBox(
                        height: ref.watch(layersVisibleProvider) ? 320 : 140,
                        child: const LayerPanel(),
                      ),
                      const Divider(height: 1),
                      const Expanded(child: _PropertiesInspector()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        EditorMode.flow => const FlowMode(),
      },
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final scene = ref.read(sceneModelProvider);
    final db = ref.read(dashboardDatabaseProvider);
    final existingId = ref.read(dashboardIdProvider);

    final name = ref.read(dashboardNameProvider);
    final description = ref.read(dashboardDescriptionProvider);
    if (!context.mounted) return;

    final (saveName, saveDesc) = await _showSaveDialog(
      context,
      initialName: name,
      initialDescription: description,
      existing: existingId != null,
    );
    if (saveName == null) return;

    final doc = documentFromScene(
      scene: scene,
      name: saveName,
      description: saveDesc,
      canvasSize: ref.read(canvasSizeProvider),
      background: ref.read(backgroundProvider),
      accent: ref.read(accentProvider),
      graphs: ref.read(flowGraphsProvider),
    );
    try {
      int id;
      if (existingId != null) {
        await db.updateDocument(existingId, doc);
        id = existingId;
      } else {
        id = await db.saveDashboard(saveName, doc);
      }
      ref.read(dashboardNameProvider.notifier).state = saveName;
      ref.read(dashboardDescriptionProvider.notifier).state = saveDesc;
      ref.read(dashboardIdProvider.notifier).state = id;
      ref.read(isDirtyProvider.notifier).state = false;
      ref.invalidate(recentDashboardsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved "$saveName"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _exportJson(BuildContext context, WidgetRef ref) async {
    final scene = ref.read(sceneModelProvider);
    final name = ref.read(dashboardNameProvider);
    final description = ref.read(dashboardDescriptionProvider);
    final doc = documentFromScene(
      scene: scene,
      name: name,
      description: description,
      canvasSize: ref.read(canvasSizeProvider),
      background: ref.read(backgroundProvider),
      accent: ref.read(accentProvider),
      graphs: ref.read(flowGraphsProvider),
    );
    final json = const JsonEncoder.withIndent('  ').convert(doc.toJson());
    final dir = await getApplicationDocumentsDirectory();
    final safeName =
        name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/$safeName.veschub.json');
    try {
      await file.writeAsString(json);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importJson(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty || !context.mounted) return;

    final path = result.files.single.path;
    if (path == null) return;

    try {
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final migrated = migrate(json);
      final doc = DashboardDocument.fromJson(migrated);

      final db = ref.read(dashboardDatabaseProvider);
      final id = await db.saveDashboard(doc.name, doc);
      ref.invalidate(recentDashboardsProvider);

      applyDocumentToEditor(
        ref,
        scene: ref.read(sceneModelProvider),
        doc: doc,
        id: id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported "${doc.name}"')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  Future<(String?, String)> _showSaveDialog(
    BuildContext context, {
    required String initialName,
    required String initialDescription,
    required bool existing,
  }) async {
    final nameController = TextEditingController(text: initialName);
    final descController = TextEditingController(text: initialDescription);

    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(existing ? 'Update dashboard' : 'Save dashboard'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional notes about this dashboard',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final n = nameController.text.trim();
                if (n.isEmpty) return;
                Navigator.of(context).pop((n, descController.text.trim()));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result == null) return (null, '');
    return result;
  }

  void _newDashboard(BuildContext context, WidgetRef ref) {
    ref.read(sceneModelProvider).replaceAll(const []);
    ref.read(selectionModelProvider).clear();
    ref.read(commandStackProvider).clear();
    ref.read(dashboardNameProvider.notifier).state = 'Untitled';
    ref.read(dashboardDescriptionProvider.notifier).state = '';
    ref.read(dashboardIdProvider.notifier).state = null;
    ref.read(canvasSizeProvider.notifier).state = kDefaultCanvasSize;
    ref.read(backgroundProvider.notifier).state = kDefaultBackground;
    ref.read(accentProvider.notifier).state = kDefaultAccent;
    ref.read(flowGraphsProvider.notifier).state = const {};
    ref.read(flowGraphProvider.notifier).state = FlowGraph.empty('graph_1');
    ref.read(flowPropertiesProvider.notifier).state = const {};
    ref.read(isDirtyProvider.notifier).state = false;
    ref.read(editorModeProvider.notifier).state = EditorMode.canvas;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Started a new dashboard')),
      );
    }
  }

  Future<void> _showOpenDialog(BuildContext context, WidgetRef ref) async {
    final db = ref.read(dashboardDatabaseProvider);
    final entries = await db.recentDashboards();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open dashboard'),
          content: SizedBox(
            width: 400,
            child: entries.isEmpty
                ? const Text('No saved dashboards yet.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final doc = db.decodeDocument(e);
                      return ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: Text(e.name),
                        subtitle: Text(
                          doc.description.isNotEmpty
                              ? '${doc.description}\nUpdated ${e.updatedAt.toLocal()}'
                              : 'Updated ${e.updatedAt.toLocal()}',
                        ),
                        onTap: () {
                          final scene = ref.read(sceneModelProvider);
                          applyDocumentToEditor(
                            ref,
                            scene: scene,
                            doc: doc,
                            id: e.id,
                            name: e.name,
                          );
                          ref.read(editorModeProvider.notifier).state =
                              EditorMode.canvas;
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
