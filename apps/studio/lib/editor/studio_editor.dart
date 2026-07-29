/// The studio editor screen: toolbar + palette + canvas + properties inspector.
///
/// This is the Phase 3 "editor that finally works" — drag-drop widgets from
/// the palette onto the [EditorCanvas], move/snap them with alignment guides,
/// edit bound properties in the inspector, and save/load to drift.
library;

import 'dart:convert';
import 'dart:io';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paint_dsl/paint_dsl.dart';
import 'package:node_graph/node_graph.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';

import '../document_bridge.dart';
import '../providers/editor_providers.dart';
import '../widgets/simple_color_picker.dart';
import 'flow_mode.dart';
import 'template_mode.dart';
import 'layer_panel.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(editorModeProvider);
    final level = ref.watch(capabilityLevelProvider);
    final commands = ref.watch(commandStackProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Veschub Studio'),
        actions: [
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
            icon: const Icon(Icons.note_add),
            onPressed: () => _newDashboard(context, ref),
            tooltip: 'New dashboard',
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _showOpenDialog(context, ref),
            tooltip: 'Open',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () => _save(context, ref),
            tooltip: 'Save',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportJson(context, ref),
            tooltip: 'Export as .veschub.json',
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importJson(context, ref),
            tooltip: 'Import .veschub.json',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: Icon(
              ref.watch(layersVisibleProvider) ? Icons.layers_clear : Icons.layers,
            ),
            onPressed: () {
              ref.read(layersVisibleProvider.notifier).state =
                  !ref.read(layersVisibleProvider);
            },
            tooltip: 'Toggle layer panel',
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
                DropdownButton<CapabilityLevel>(
                  value: level,
                  items: CapabilityLevel.values
                      .map((l) => DropdownMenuItem(
                            value: l,
                            child: Text(l.name.capitalize()),
                          ))
                      .toList(),
                  onChanged: (l) => ref
                      .read(capabilityLevelProvider.notifier)
                      .state = l ?? level,
                ),
              ],
            ),
          ),
        ),
      ),
      body: switch (mode) {
        EditorMode.template => const TemplateMode(),
        EditorMode.canvas => Row(
            children: [
              const _WidgetPalette(),
              Expanded(child: _CanvasArea()),
              SizedBox(
                width: 280,
                child: ref.watch(layersVisibleProvider)
                    ? const LayerPanel()
                    : const _PropertiesInspector(),
              ),
            ],
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
    final safeName = name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
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

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// The drag-drop widget palette.
class _WidgetPalette extends ConsumerWidget {
  const _WidgetPalette();

  static Binding T(String key) => Binding.telemetry(key: key);
  static Binding L(Object v) => Binding.literal(value: v);

  /// Per-template props — shape the widget itself, not just its container.
  /// Each template has a name, icon, and a map of properties that make it
  /// visually distinct (dial geometry, needle, ticks, colour scheme).

  static final _templates = <String, List<({String name, IconData icon, Map<String, Binding> props})>>{
    'gauge': [
      // --- Car-inspired dial geometries ---
      (
        name: 'BMW Classic',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 270, start: 135, ticks: 20, arc: 8, colour: 0xFFFF4400, accent: 0xFFFFffff, bg: 0xFF0D0D0D, rad: 4, bw: 0),
      ),
      (
        name: 'VW Digital',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 180, start: 180, ticks: 8, arc: 6, colour: 0xFF4FC3F7, accent: 0xFF888888, bg: 0xFF0A0A14, rad: 8, bw: 1, bc: 0x22222222),
      ),
      (
        name: 'Mercedes',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 270, start: 135, ticks: 12, arc: 10, colour: 0xFFC0C0C0, accent: 0xFF808080, bg: 0xFF080808, rad: 12, bw: 1, bc: 0x22FFFFFF),
      ),
      (
        name: 'Tesla S',
        icon: Icons.speed,
        props: _dial(needle: 'arc', sweep: 270, start: 135, ticks: 4, arc: 3, colour: 0xFFFFFFFF, accent: 0xFF444444, bg: 0xFF080808, rad: 0, bw: 0),
      ),
      (
        name: 'Audi VC',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 270, start: 135, ticks: 24, arc: 6, colour: 0xFFF05030, accent: 0xFFEEEEEE, bg: 0xFF050510, rad: 6, bw: 0),
      ),
      (
        name: 'Porsche',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 270, start: 135, ticks: 30, arc: 8, colour: 0xFF00CC66, accent: 0xFFCCCC00, bg: 0xFF0A0A0A, rad: 8, bw: 1, bc: 0x22FFD700),
      ),
      (
        name: 'Rally Pod',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 360, start: 90, ticks: 20, arc: 12, colour: 0xFFFF4400, accent: 0xFF000000, bg: 0xFF000000, rad: 4, bw: 1, bc: 0x44FF4400),
      ),
      (
        name: 'Classic',
        icon: Icons.speed,
        props: _dial(needle: 'needle', sweep: 270, start: 135, ticks: 10, arc: 8, colour: 0xFFFFFFFF, accent: 0xFF888888, bg: 0xFF111111, rad: 8, bw: 1, bc: 0x22444444),
      ),
    ],
    'bar': [
      (
        name: 'Horizontal',
        icon: Icons.bar_chart,
        props: {'value': T('duty'), 'min': L(0), 'max': L(1), 'color': L(0xFF4FC3F7), 'backgroundColor': L(0xFF111122), 'borderRadius': L(6), 'padding': L(8), 'opacity': L(1.0)},
      ),
      (
        name: 'Vertical',
        icon: Icons.bar_chart,
        props: {'value': T('duty'), 'min': L(0), 'max': L(1), 'color': L(0xFF66BB6A), 'orientation': L('vertical'), 'backgroundColor': L(0xFF111122), 'borderRadius': L(6), 'padding': L(8)},
      ),
      (
        name: 'Thin',
        icon: Icons.bar_chart,
        props: {'value': T('current.motor'), 'min': L(0), 'max': L(100), 'color': L(0xFFEF5350), 'backgroundColor': L(0x00000000), 'borderRadius': L(2), 'padding': L(2), 'opacity': L(0.9)},
      ),
      (
        name: 'Wide Card',
        icon: Icons.bar_chart,
        props: {'value': T('duty'), 'min': L(0), 'max': L(1), 'color': L(0xFFFF9800), 'backgroundColor': L(0xFF1E1E2E), 'borderRadius': L(12), 'borderWidth': L(1), 'borderColor': L(0x33FFFFFF), 'padding': L(16)},
      ),
    ],
    'text': [
      (
        name: 'Sans',
        icon: Icons.text_fields,
        props: {'value': T('v_in'), 'label': L('Voltage'), 'unit': L('V'), 'fontSize': L(40), 'color': L(0xFFFFFFFF), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'padding': L(10)},
      ),
      (
        name: 'Mono',
        icon: Icons.text_fields,
        props: {'value': T('erpm'), 'label': L('RPM'), 'fontSize': L(48), 'fontWeight': L('bold'), 'color': L(0xFF4FC3F7), 'backgroundColor': L(0x00000000), 'padding': L(8)},
      ),
      (
        name: 'Compact',
        icon: Icons.text_fields,
        props: {'value': T('current.motor'), 'label': L('Motor'), 'unit': L('A'), 'fontSize': L(24), 'color': L(0xFF66BB6A), 'backgroundColor': L(0xFF1A1A2A), 'borderRadius': L(6), 'padding': L(6)},
      ),
    ],
    'chart': [
      (
        name: 'Line Chart',
        icon: Icons.show_chart,
        props: {'value': T('erpm'), 'min': L(0), 'max': L(30000), 'label': L('RPM'), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'lineWidth': L(2), 'smoothCurve': L(true), 'padding': L(8)},
      ),
      (
        name: 'Area Chart',
        icon: Icons.show_chart,
        props: {'value': T('current.motor'), 'min': L(0), 'max': L(100), 'label': L('Motor A'), 'color': L(0xFF66BB6A), 'backgroundColor': L(0xFF0D0D1A), 'borderRadius': L(8), 'fillArea': L(true), 'fillColor': L(0x1166BB6A), 'lineWidth': L(1.5), 'padding': L(8)},
      ),
      (
        name: 'Bare Chart',
        icon: Icons.show_chart,
        props: {'value': T('erpm'), 'min': L(0), 'max': L(30000), 'backgroundColor': L(0x00000000), 'showGrid': L(false), 'lineWidth': L(3), 'borderRadius': L(0), 'padding': L(0)},
      ),
    ],
    'status': [
      (
        name: 'Pill',
        icon: Icons.warning,
        props: {'fault': T('fault'), 'backgroundColor': L(0xFF1A1A2E), 'borderRadius': L(20), 'fontSize': L(14), 'padding': L(10)},
      ),
      (
        name: 'Inline',
        icon: Icons.warning,
        props: {'fault': T('fault'), 'backgroundColor': L(0x00000000), 'borderRadius': L(4), 'fontSize': L(12), 'padding': L(4)},
      ),
    ],
    'image': [
      (
        name: 'Rounded',
        icon: Icons.image,
        props: {'src': L('assets/images/placeholder.png'), 'borderRadius': L(12), 'borderWidth': L(1), 'borderColor': L(0x44FFFFFF)},
      ),
      (
        name: 'Shadowed',
        icon: Icons.image,
        props: {'src': L('assets/images/placeholder.png'), 'borderRadius': L(8), 'shadowBlur': L(8), 'shadowColor': L(0x44000000), 'shadowOffsetY': L(4)},
      ),
    ],
    'web': [
      (
        name: 'Page',
        icon: Icons.public,
        props: {'url': L('https://example.com'), 'title': L('Live page'), 'borderRadius': L(8), 'padding': L(4)},
      ),
    ],
    'paint': [
      (
        name: 'Custom',
        icon: Icons.brush,
        props: {},
      ),
    ],
    'digitalspeed': [
      (
        name: 'Tesla Style',
        icon: Icons.speed,
        props: {'value': T('erpm'), 'unit': L('km/h'), 'fontSize': L(72), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'showUnit': L(true), 'backgroundColor': L(0xFF000000), 'borderRadius': L(0), 'padding': L(16), 'fontWeight': L('w200')},
      ),
      (
        name: 'Compact',
        icon: Icons.speed,
        props: {'value': T('erpm'), 'unit': L('mph'), 'fontSize': L(48), 'color': L(0xFF4FC3F7), 'accent': L(0xFF666666), 'showUnit': L(true), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'padding': L(12)},
      ),
      (
        name: 'With Sub',
        icon: Icons.speed,
        props: {'value': T('erpm'), 'unit': L('km/h'), 'fontSize': L(64), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'showUnit': L(true), 'subLabel': L('Range'), 'subValue': T('battery_pct'), 'backgroundColor': L(0xFF0A0A0A), 'borderRadius': L(0), 'padding': L(16)},
      ),
    ],
    'music': [
      (
        name: 'Player',
        icon: Icons.music_note,
        props: {'title': L('Track Name'), 'artist': L('Artist'), 'progress': L(30), 'duration': L(180), 'showControls': L(true), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'albumColor': L(0xFF333333), 'backgroundColor': L(0xFF1A1A2E), 'borderRadius': L(12), 'padding': L(12)},
      ),
      (
        name: 'Mini',
        icon: Icons.music_note,
        props: {'title': L('Now Playing'), 'artist': L('Artist'), 'showControls': L(false), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'albumColor': L(0xFF444444), 'backgroundColor': L(0xFF0D0D1A), 'borderRadius': L(8), 'padding': L(8)},
      ),
    ],
    'tripstats': [
      (
        name: 'Trip Info',
        icon: Icons.info_outline,
        props: {'label1': L('Distance'), 'value1': T('trip_distance'), 'unit1': L('km'), 'label2': L('Time'), 'value2': T('trip_time'), 'unit2': L('min'), 'label3': L('Avg Speed'), 'value3': T('avg_speed'), 'unit3': L('km/h'), 'label4': L('Energy'), 'value4': T('energy_used'), 'unit4': L('Wh'), 'columns': L(2), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'fontSize': L(20), 'padding': L(12)},
      ),
      (
        name: 'Compact',
        icon: Icons.info_outline,
        props: {'label1': L('ODO'), 'value1': T('odometer'), 'unit1': L('km'), 'label2': L('Trip'), 'value2': T('trip_distance'), 'unit2': L('km'), 'label3': L('Max'), 'value3': T('max_speed'), 'unit3': L('km/h'), 'label4': L('Avg'), 'value4': T('avg_speed'), 'unit4': L('km/h'), 'columns': L(2), 'color': L(0xFF4FC3F7), 'accent': L(0xFF666666), 'backgroundColor': L(0xFF0A0A14), 'borderRadius': L(6), 'fontSize': L(16), 'padding': L(8)},
      ),
    ],
    'power': [
      (
        name: 'Power Meter',
        icon: Icons.bolt,
        props: {'power': T('power'), 'maxPower': L(10000), 'color': L(0xFF00FF88), 'regenColor': L(0xFF4488FF), 'accent': L(0xFF888888), 'showBars': L(true), 'label': L('Power'), 'backgroundColor': L(0xFF0D0D1A), 'borderRadius': L(8), 'fontSize': L(28), 'padding': L(12)},
      ),
      (
        name: 'Simple',
        icon: Icons.bolt,
        props: {'power': T('power'), 'maxPower': L(5000), 'color': L(0xFFFF9800), 'regenColor': L(0xFF4FC3F7), 'accent': L(0xFF666666), 'showBars': L(false), 'label': L('Watts'), 'backgroundColor': L(0xFF111122), 'borderRadius': L(6), 'fontSize': L(24), 'padding': L(8)},
      ),
    ],
    'warnings': [
      (
        name: 'Warning Icons',
        icon: Icons.warning,
        props: {'activeWarnings': L('temp,battery'), 'color': L(0xFFFF4444), 'warningColor': L(0xFFFFAA00), 'infoColor': L(0xFF4488FF), 'iconSize': L(24), 'backgroundColor': L(0xFF1A1A2E), 'borderRadius': L(8), 'padding': L(8)},
      ),
      (
        name: 'Status',
        icon: Icons.check_circle,
        props: {'activeWarnings': L(''), 'color': L(0xFF00CC66), 'warningColor': L(0xFFFFAA00), 'infoColor': L(0xFF4488FF), 'iconSize': L(20), 'backgroundColor': L(0x00000000), 'borderRadius': L(0), 'padding': L(4)},
      ),
    ],
    'minigauge': [
      (
        name: 'Battery',
        icon: Icons.battery_full,
        props: {'value': T('battery_pct'), 'min': L(0), 'max': L(100), 'label': L('Battery'), 'unit': L('%'), 'icon': L('battery'), 'style': L('arc'), 'color': L(0xFF00CC66), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'fontSize': L(16), 'padding': L(8)},
      ),
      (
        name: 'Temp Bar',
        icon: Icons.thermostat,
        props: {'value': T('temp.mosfet'), 'min': L(0), 'max': L(100), 'label': L('Temp'), 'unit': L('°C'), 'icon': L('temp'), 'style': L('bar'), 'color': L(0xFFFF5722), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF1A1A2E), 'borderRadius': L(6), 'fontSize': L(14), 'padding': L(6)},
      ),
      (
        name: 'Fuel',
        icon: Icons.local_gas_station,
        props: {'value': T('battery_pct'), 'min': L(0), 'max': L(100), 'label': L('Fuel'), 'unit': L('%'), 'icon': L('fuel'), 'style': L('arc'), 'color': L(0xFFFF9800), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF0D0D1A), 'borderRadius': L(8), 'fontSize': L(14), 'padding': L(8)},
      ),
    ],
    'appgrid': [
      (
        name: 'CarPlay',
        icon: Icons.apps,
        props: {'apps': L('phone,music,maps,messages,settings,weather,clock,calculator'), 'columns': L(4), 'iconSize': L(28), 'showLabels': L(true), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF000000), 'borderRadius': L(0), 'padding': L(16)},
      ),
      (
        name: 'Compact',
        icon: Icons.apps,
        props: {'apps': L('phone,music,maps,settings'), 'columns': L(2), 'iconSize': L(24), 'showLabels': L(false), 'color': L(0xFF4FC3F7), 'accent': L(0xFF666666), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'padding': L(12)},
      ),
    ],
    'statusbar': [
      (
        name: 'Top Bar',
        icon: Icons.bar_chart,
        props: {'time': L('12:34'), 'battery': L(0.85), 'signal': L(0.75), 'showTime': L(true), 'showBattery': L(true), 'showSignal': L(true), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF000000), 'borderRadius': L(0), 'fontSize': L(13), 'padding': L(8)},
      ),
      (
        name: 'Minimal',
        icon: Icons.bar_chart,
        props: {'time': L(''), 'battery': L(0.5), 'signal': L(0.5), 'showTime': L(false), 'showBattery': L(true), 'showSignal': L(false), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'backgroundColor': L(0x00000000), 'borderRadius': L(0), 'fontSize': L(12), 'padding': L(4)},
      ),
    ],
    'climate': [
      (
        name: 'Temperature',
        icon: Icons.thermostat,
        props: {'temperature': L(22), 'targetTemp': L(23), 'fanSpeed': L(0.5), 'mode': L('auto'), 'unit': L('°C'), 'color': L(0xFFFFFFFF), 'accent': L(0xFF888888), 'backgroundColor': L(0xFF1A1A2E), 'borderRadius': L(12), 'fontSize': L(32), 'padding': L(16)},
      ),
      (
        name: 'Compact',
        icon: Icons.thermostat,
        props: {'temperature': L(20), 'mode': L('cool'), 'unit': L('°F'), 'color': L(0xFF4FC3F7), 'accent': L(0xFF666666), 'backgroundColor': L(0xFF0D0D1A), 'borderRadius': L(8), 'fontSize': L(24), 'padding': L(12)},
      ),
    ],
    'car_viz': [
      (
        name: 'Lane Assist',
        icon: Icons.directions_car,
        props: {'laneLeft': L(false), 'laneRight': L(false), 'carAhead': L(false), 'label': L('Lane Keep'), 'color': L(0xFFFFFFFF), 'accent': L(0xFF4488FF), 'backgroundColor': L(0xFF0A0A14), 'borderRadius': L(8), 'padding': L(8)},
      ),
    ],
    'map': [
      (
        name: 'Navigation',
        icon: Icons.map,
        props: {'label': L('Navigation'), 'eta': L('15 min'), 'distance': L('8.2 km'), 'nextTurn': L('Turn right'), 'color': L(0xFFFFFFFF), 'accent': L(0xFF4488FF), 'backgroundColor': L(0xFF111122), 'borderRadius': L(8), 'padding': L(8)},
      ),
    ],
  };

  /// Build a gauge template: dial geometry + container cosmetics.
  static Map<String, Binding> _dial({
    required String needle,
    required double sweep, required double start,
    required int ticks, required double arc,
    required int colour, required int accent,
    required int bg, required double rad,
    required double bw, int bc = 0,
  }) => {
    'value': T('erpm'), 'min': L(0), 'max': L(30000), 'label': L('RPM'),
    'needleStyle': L(needle), 'sweepAngle': L(sweep), 'startAngle': L(start),
    'tickCount': L(ticks), 'arcWidth': L(arc),
    'color': L(colour), 'accent': L(accent),
    'backgroundColor': L(bg), 'borderRadius': L(rad),
    'borderWidth': L(bw), 'borderColor': L(bc),
    'opacity': L(1.0), 'padding': L(12), 'fontSize': L(28),
  };

  static IconData _kindIcon(String kind) => switch (kind) {
        'gauge' => Icons.speed,
        'bar' => Icons.bar_chart,
        'text' => Icons.text_fields,
        'chart' => Icons.show_chart,
        'status' => Icons.info_outline,
        'image' => Icons.image,
        'web' => Icons.public,
        'paint' => Icons.brush,
        'digitalspeed' => Icons.speed,
        'music' => Icons.music_note,
        'tripstats' => Icons.info_outline,
        'power' => Icons.bolt,
        'warnings' => Icons.warning,
        'minigauge' => Icons.tune,
        'appgrid' => Icons.apps,
        'statusbar' => Icons.bar_chart,
        'climate' => Icons.thermostat,
        'car_viz' => Icons.directions_car,
        'map' => Icons.map,
        _ => Icons.widgets,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(capabilityLevelProvider);
    final kinds = builtInWidgets.entries
        .where((e) => level.includes(e.value.level))
        .map((e) => e.key)
        .toList();

    return Container(
      width: 200,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Widgets', style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: kinds.length,
              itemBuilder: (context, index) {
                final kind = kinds[index];
                final tpls = _templates[kind] ?? const [];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: ExpansionTile(
                    leading: Icon(_kindIcon(kind), size: 20),
                    title: Text(kind.capitalize(), style: const TextStyle(fontSize: 13)),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                    childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
                    initiallyExpanded: index == 0,
                    children: [
                      for (final tpl in tpls)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: Draggable<Map<String, dynamic>>(
                            data: {'kind': kind, 'props': tpl.props},
                            feedback: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(tpl.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _PaletteTile(kind: kind, label: tpl.name, icon: tpl.icon),
                            ),
                            child: _PaletteTile(kind: kind, label: tpl.name, icon: tpl.icon),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  final String kind;
  final String? label;
  final IconData? icon;
  const _PaletteTile({required this.kind, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon ?? Icons.widgets, size: 16),
      title: Text(label ?? kind, style: const TextStyle(fontSize: 11)),
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      minLeadingWidth: 24,
    );
  }
}
/// The canvas area with drag-drop acceptance.
class _CanvasArea extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends ConsumerState<_CanvasArea> {
  final _dropTargetKey = GlobalKey();

  /// Key on the inner canvas container (inside FittedBox), used for
  /// coordinate conversion that correctly accounts for FittedBox scaling.
  final _canvasKey = GlobalKey();

  Offset _toCanvasPosition(Offset globalPos) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return globalPos;
    return box.globalToLocal(globalPos);
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);
    final commands = ref.watch(commandStackProvider);
    final canvasSize = ref.watch(canvasSizeProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: TextEditingController(
                    text: canvasSize.width.toString(),
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'W',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: (v) {
                    final w = double.tryParse(v);
                    if (w != null && w > 0) {
                      ref.read(canvasSizeProvider.notifier).state =
                          CanvasSize(width: w, height: canvasSize.height);
                      ref.read(isDirtyProvider.notifier).state = true;
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('×', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: TextEditingController(
                    text: canvasSize.height.toString(),
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'H',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: (v) {
                    final h = double.tryParse(v);
                    if (h != null && h > 0) {
                      ref.read(canvasSizeProvider.notifier).state =
                          CanvasSize(width: canvasSize.width, height: h);
                      ref.read(isDirtyProvider.notifier).state = true;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.screen_rotation, size: 16),
                tooltip: 'Swap orientation',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  ref.read(canvasSizeProvider.notifier).state = CanvasSize(
                    width: canvasSize.height,
                    height: canvasSize.width,
                  );
                  ref.read(isDirtyProvider.notifier).state = true;
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.grid_on,
                  size: 16,
                  color: ref.watch(gridVisibleProvider)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Toggle grid',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  ref.read(gridVisibleProvider.notifier).state =
                      !ref.read(gridVisibleProvider);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: FittedBox(
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: DragTarget<Map<String, dynamic>>(
                  key: _dropTargetKey,
                  onAcceptWithDetails: (details) {
                    final kind = details.data['kind'] as String;
                    final tplProps = details.data['props'] as Map<String, Binding>?;
                    final id = ref.read(idGeneratorProvider).next();
                    final localPos = _toCanvasPosition(details.offset);
                    final node = CanvasNode(
                      id: id,
                      transform: NodeTransforms.compose(translation: localPos),
                      data: WidgetInstance(
                        id: id,
                        kind: kind,
                        properties: tplProps ?? _defaultProperties(kind),
                      ),
                    );
                    commands.execute(AddNodeCommand(node));
                    ref.read(isDirtyProvider.notifier).state = true;
                  },
                  builder: (context, candidate, rejected) {
                    final borderColor = candidate.isNotEmpty
                        ? Colors.blue
                        : Theme.of(context).colorScheme.outline;
                    return Container(
                      key: _canvasKey,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 2),
                        color: candidate.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.05)
                            : Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
                      ),
                      child: EditorCanvas(
                        scene: scene,
                        selection: selection,
                        commands: commands,
                        canvasSize: Size(canvasSize.width, canvasSize.height),
                        showGrid: ref.watch(gridVisibleProvider),
                        onCommandExecuted: (_) =>
                            ref.read(isDirtyProvider.notifier).state = true,
                        nodeBuilder: (node) {
                          final w = node.data as WidgetInstance?;
                          if (w == null) {
                            return const Center(child: Text('No data'));
                          }
                          final store = ref.read(canvasPreviewTelemetryProvider);
                          return buildWidget(w, _resolve(w, store));
                        },
                        nodeWidth: (node) {
                          final w = node.data as WidgetInstance?;
                          final p = w?.properties['width']
                              ?.mapOrNull(literal: (b) => b.value);
                          return (p as num?)?.toDouble() ?? kDefaultNodeWidth;
                        },
                        nodeHeight: (node) {
                          final h = node.data as WidgetInstance?;
                          final p = h?.properties['height']
                              ?.mapOrNull(literal: (b) => b.value);
                          return (p as num?)?.toDouble() ?? kDefaultNodeHeight;
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Map<String, Binding> _defaultProperties(String kind) {
    return switch (kind) {
      'gauge' => {
          'value': const Binding.telemetry(key: 'erpm'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 30000),
          'label': const Binding.literal(value: 'RPM'),
        },
      'bar' => {
          'value': const Binding.telemetry(key: 'duty'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 1),
        },
      'text' => {
          'value': const Binding.telemetry(key: 'v_in'),
          'label': const Binding.literal(value: 'Value'),
        },
      'status' => {
          'fault': const Binding.telemetry(key: 'fault'),
        },
      'chart' => {
          'value': const Binding.telemetry(key: 'erpm'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 30000),
          'label': const Binding.literal(value: 'RPM'),
        },
      'image' => {
          'src': const Binding.literal(value: 'assets/images/placeholder.png'),
        },
      'web' => {
          'url': const Binding.literal(value: 'https://example.com'),
          'title': const Binding.literal(value: 'Live page'),
        },
      'paint' => {
          'program': Binding.literal(value: _samplePaintProgram.toJson()),
          'r': const Binding.telemetry(key: 'temp.mosfet'),
        },
      _ => <String, Binding>{},
    };
  }

  static Map<String, dynamic> _resolve(WidgetInstance w, TelemetryStore store) {
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
}

/// The properties inspector for the current selection.
class _PropertiesInspector extends ConsumerWidget {
  const _PropertiesInspector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);
    final level = ref.watch(capabilityLevelProvider);

    if (selection.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade300)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select a widget to edit its properties',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final node = scene[selection.single ?? selection.ids.first];
    if (node == null) return const SizedBox.shrink();
    final widget = node.data as WidgetInstance?;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Row(
            children: [
              Text('Properties', style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete widget',
                onPressed: () {
                  ref.read(commandStackProvider).execute(RemoveNodesCommand([node]));
                  ref.read(selectionModelProvider).clear();
                  ref.read(isDirtyProvider.notifier).state = true;
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget != null) ...[
            _Field(label: 'ID', value: widget.id),
            _Field(label: 'Kind', value: widget.kind),
            if (!transformsUnlockedAt(level))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Transforms locked — switch to Advanced to move widgets.',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ),
            const Divider(),
            ..._PropertiesInspector._buildProperties(node, widget, level),
          ],
        ],
      ),
    );
  }

  static List<Widget> _buildProperties(
    CanvasNode node,
    WidgetInstance widget,
    CapabilityLevel level,
  ) {
    if (widget.kind == 'paint') {
      final entries = Map<String, Binding>.from(widget.properties);
      return [
        if (level.includes(CapabilityLevel.expert))
          _PaintProgramEditor(node: node, widget: widget)
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'Switch to Expert to edit the paint program.',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        for (final m in allProperties(widget.kind))
          if (m.key != 'program')
            _BindingField(
              node: node, widget: widget, name: m.key,
              binding: entries[m.key] ?? _defaultBinding(m),
            ),
      ];
    }

    final all = allProperties(widget.kind);
    final basic = all.where((m) => m.minLevel == CapabilityLevel.basic).toList();
    final advanced = all.where((m) => m.minLevel == CapabilityLevel.advanced).toList();
    final expert = all.where((m) => m.minLevel == CapabilityLevel.expert).toList();
    final entries = Map<String, Binding>.from(widget.properties);

    return [
      for (final m in basic)
        _BindingField(
          node: node, widget: widget, name: m.key,
          binding: entries[m.key] ?? _defaultBinding(m),
        ),
      if (advanced.isNotEmpty)
        _ExpandableSection(
          title: 'Advanced',
          initiallyExpanded: true,
          children: [
            for (final m in advanced)
              _BindingField(
                node: node, widget: widget, name: m.key,
                binding: entries[m.key] ?? _defaultBinding(m),
              ),
          ],
        ),
      if (expert.isNotEmpty)
        _ExpandableSection(
          title: 'Expert',
          initiallyExpanded: false,
          children: [
            for (final m in expert)
              _BindingField(
                node: node, widget: widget, name: m.key,
                binding: entries[m.key] ?? _defaultBinding(m),
              ),
          ],
        ),
    ];
  }

  static Binding _defaultBinding(PropertyMeta m) {
    // Provide sensible defaults so the property shows up editable.
    if (m.key == 'visible') return const Binding.literal(value: true);
    if (m.key == 'opacity') return const Binding.literal(value: 1.0);
    if (m.key == 'padding') return const Binding.literal(value: 12);
    if (m.key == 'width') return const Binding.literal(value: 300);
    if (m.key == 'height') return const Binding.literal(value: 220);
    if (m.key == 'orientation') return const Binding.literal(value: 'horizontal');
    if (m.key == 'needleStyle') return const Binding.literal(value: 'arc');
    if (m.key == 'fontSize') return const Binding.literal(value: 20);
    if (m.key == 'fontWeight') return const Binding.literal(value: 'bold');
    if (m.key == 'sweepAngle') return const Binding.literal(value: 270.0);
    if (m.key == 'startAngle') return const Binding.literal(value: 135.0);
    if (m.key == 'tickCount') return const Binding.literal(value: 10);
    if (m.key == 'arcWidth') return const Binding.literal(value: 10.0);
    if (m.key == 'lineWidth') return const Binding.literal(value: 2.0);
    if (m.key == 'showGrid') return const Binding.literal(value: true);
    if (m.key == 'smoothCurve') return const Binding.literal(value: true);
    if (m.key == 'fillArea') return const Binding.literal(value: false);
    if (m.key == 'window') return const Binding.literal(value: 120);
    if (m.key == 'js') return const Binding.literal(value: true);
    final isColour = m.key == 'color' || m.key == 'accent' || m.key == 'backgroundColor' || m.key == 'borderColor' || m.key == 'shadowColor' || m.key == 'fillColor' || m.key == 'gridColor' || m.key == 'tint';
    if (isColour) return const Binding.literal(value: 0xFFFFFFFF);
    final isNum = m.key == 'min' || m.key == 'max' || m.key == 'borderRadius' || m.key == 'borderWidth' || m.key == 'shadowBlur' || m.key == 'shadowOffsetY' || m.key == 'letterSpacing' || m.key == 'barRadius';
    if (isNum) return const Binding.literal(value: 0);
    return const Binding.literal(value: 0);
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final List<Widget> children;
  const _ExpandableSection({
    required this.title,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...widget.children,
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _BindingField extends ConsumerWidget {
  final CanvasNode node;
  final WidgetInstance widget;
  final String name;
  final Binding binding;
  const _BindingField({
    required this.node,
    required this.widget,
    required this.name,
    required this.binding,
  });

  void _commit(WidgetRef ref, Binding newBinding) {
    final newProps = Map<String, Binding>.from(widget.properties);
    newProps[name] = newBinding;
    final newWidget = widget.copyWith(properties: newProps);
    ref.read(commandStackProvider).execute(
          UpdateNodeDataCommand(
            id: node.id,
            oldData: widget,
            newData: newWidget,
          ),
        );
    ref.read(isDirtyProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = visibleProperties(widget.kind, ref.watch(capabilityLevelProvider))
        .firstWhere(
          (m) => m.key == name,
          orElse: () => PropertyMeta(key: name, minLevel: CapabilityLevel.basic, label: name),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(meta.label, style: const TextStyle(fontWeight: FontWeight.w500))),
              _BindingTypeChip(label: 'Lit', active: binding is LiteralBinding, onTap: () => _commit(ref, const Binding.literal(value: 0))),
              _BindingTypeChip(label: 'Tel', active: binding is TelemetryBinding, onTap: () => _commit(ref, const Binding.telemetry(key: 'erpm'))),
              _BindingTypeChip(label: 'F(x)', active: binding is FormulaBinding, onTap: () => _commit(ref, const Binding.formula(expression: 'erpm / 1000'))),
              if (ref.watch(capabilityLevelProvider).includes(CapabilityLevel.expert))
                _BindingTypeChip(label: 'Graph', active: binding is GraphBinding, onTap: () => _commit(ref, Binding.graph(graphId: '', output: ''))),
            ],
          ),
          const SizedBox(height: 4),
          binding.map(
            literal: (b) => _LiteralEditor(
              value: b.value,
              onChanged: (v) => _commit(ref, Binding.literal(value: v)),
            ),
            telemetry: (b) => _TelemetryEditor(
              currentKey: b.key,
              onChanged: (k) => _commit(ref, Binding.telemetry(key: k)),
            ),
            graph: (b) => _GraphEditor(
              graphId: b.graphId,
              output: b.output,
              onChanged: (gid, out) =>
                  _commit(ref, Binding.graph(graphId: gid, output: out)),
            ),
            formula: (b) => _FormulaEditor(
              expression: b.expression,
              onChanged: (expr) =>
                  _commit(ref, Binding.formula(expression: expr)),
            ),
          ),
        ],
      ),
    );
  }
}

class _BindingTypeChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BindingTypeChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: active ? Theme.of(context).colorScheme.primaryContainer : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, color: active ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.grey.shade700)),
      ),
    );
  }
}

class _LiteralEditor extends StatefulWidget {
  final Object value;
  final ValueChanged<Object> onChanged;
  const _LiteralEditor({required this.value, required this.onChanged});

  @override
  State<_LiteralEditor> createState() => _LiteralEditorState();
}

class _LiteralEditorState extends State<_LiteralEditor> {
  late final TextEditingController _controller;
  bool _isColor = false;

  @override
  void initState() {
    super.initState();
    _isColor = widget.value is int && (widget.value as int) > 0xFF000000;
    _controller = TextEditingController(text: _format(widget.value));
  }

  String _format(Object v) {
    if (v is num) return v.toString();
    return v.toString();
  }

  @override
  void didUpdateWidget(covariant _LiteralEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
      _isColor = widget.value is int && (widget.value as int) > 0xFF000000;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isColor) {
      final colorVal = (widget.value as num).toInt();
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<int>(
                context: context,
                builder: (context) => SimpleColorPicker(current: colorVal),
              );
              if (picked != null) widget.onChanged(picked);
            },
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: Color(colorVal),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _isColor = false),
            child: const Text('Hex', style: TextStyle(fontSize: 11)),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true),
            onFieldSubmitted: (s) => _apply(s),
          ),
        ),
        if (widget.value is int && (widget.value as int) > 0xFF000000)
          TextButton(
            onPressed: () => setState(() => _isColor = true),
            child: const Text('Color', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  void _apply(String s) {
    final trimmed = s.trim();
    final n = num.tryParse(trimmed);
    widget.onChanged(n ?? trimmed);
  }
}

class _TelemetryEditor extends StatefulWidget {
  final String currentKey;
  final ValueChanged<String> onChanged;
  const _TelemetryEditor({required this.currentKey, required this.onChanged});

  @override
  State<_TelemetryEditor> createState() => _TelemetryEditorState();
}

class _TelemetryEditorState extends State<_TelemetryEditor> {
  bool _manual = false;

  @override
  Widget build(BuildContext context) {
    if (_manual) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: widget.currentKey,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(isDense: true, hintText: 'e.g. fault'),
              onFieldSubmitted: (v) {
                if (v.trim().isNotEmpty) widget.onChanged(v.trim());
                setState(() => _manual = false);
              },
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _manual = false),
            child: const Text('Pick', style: TextStyle(fontSize: 11)),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: DropdownButton<String>(
            value: TelemetryKey.all.contains(widget.currentKey) ? widget.currentKey : null,
            isExpanded: true,
            hint: Text(widget.currentKey, style: const TextStyle(fontSize: 12)),
            items: [for (final k in TelemetryKey.all) DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(fontSize: 12)))],
            onChanged: (v) { if (v != null) widget.onChanged(v); },
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _manual = true),
          child: const Text('Manual', style: TextStyle(fontSize: 11)),
        ),
      ],
    );
  }
}

class _FormulaEditor extends StatelessWidget {
  final String expression;
  final ValueChanged<String> onChanged;
  const _FormulaEditor({required this.expression, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.functions, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: expression),
            decoration: const InputDecoration(
              hintText: 'erpm / 1000',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _GraphEditor extends StatelessWidget {
  final String graphId;
  final String output;
  final void Function(String, String) onChanged;
  const _GraphEditor({required this.graphId, required this.output, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: graphId,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true, labelText: 'Graph', labelStyle: TextStyle(fontSize: 10)),
            onFieldSubmitted: (v) => onChanged(v.trim(), output),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: output,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true, labelText: 'Output', labelStyle: TextStyle(fontSize: 10)),
            onFieldSubmitted: (v) => onChanged(graphId, v.trim()),
          ),
        ),
      ],
    );
  }
}

/// A JSON editor for a `paint` widget's program. Edits are committed through
/// an [UpdateNodeDataCommand] so they participate in undo/redo.
class _PaintProgramEditor extends ConsumerStatefulWidget {
  final CanvasNode node;
  final WidgetInstance widget;
  const _PaintProgramEditor({required this.node, required this.widget});

  @override
  ConsumerState<_PaintProgramEditor> createState() =>
      _PaintProgramEditorState();
}

class _PaintProgramEditorState extends ConsumerState<_PaintProgramEditor> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _encodedProgram());
  }

  @override
  void didUpdateWidget(covariant _PaintProgramEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final encoded = _encodedProgram();
    if (encoded != _controller.text && _error == null) {
      _controller.text = encoded;
    }
  }

  String _encodedProgram() {
    final binding = widget.widget.properties['program'];
    final value = binding?.mapOrNull(literal: (b) => b.value);
    if (value is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    return const JsonEncoder.withIndent('  ')
        .convert(const <String, dynamic>{'ops': <dynamic>[]});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final text = _controller.text;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _error = 'Program must be a JSON object.');
        return;
      }
      // Validate it round-trips through PaintProgram.
      PaintProgram.fromJson(Map<String, dynamic>.from(decoded));
      final newWidget = widget.widget.copyWith(
        properties: {
          ...widget.widget.properties,
          'program': Binding.literal(value: decoded),
        },
      );
      ref.read(commandStackProvider).execute(
            UpdateNodeDataCommand(
              id: widget.node.id,
              oldData: widget.node.data,
              newData: newWidget,
            ),
          );
      ref.read(isDirtyProvider.notifier).state = true;
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paint program',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: 16,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: _commit,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Apply'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  _controller.text = const JsonEncoder.withIndent('  ')
                      .convert(_samplePaintProgram.toJson());
                  setState(() => _error = null);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Sample'),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Coords may be numbers or "\$var" refs; every non-program '
              'property is a variable.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
