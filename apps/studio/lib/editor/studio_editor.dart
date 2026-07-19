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
    // Uses file_picker when available; falls back to listing .veschub.json
    // files in the documents directory.
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.veschub.json'))
        .toList();

    if (!context.mounted) return;

    if (files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No .veschub.json files found in documents')),
      );
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Import .veschub.json'),
        children: [
          for (final f in files)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f.path),
              child: Text(f.uri.pathSegments.last),
            ),
        ],
      ),
    );
    if (selected == null || !context.mounted) return;

    try {
      final raw = await File(selected).readAsString();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(capabilityLevelProvider);
    final available = builtInWidgets.entries
        .where((e) => level.includes(e.value.level))
        .toList();

    return Container(
      width: 180,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child:
                Text('Widgets', style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final entry in available)
                  Draggable<Map<String, dynamic>>(
                    data: {'kind': entry.key},
                    feedback: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(entry.key,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _PaletteTile(kind: entry.key),
                    ),
                    child: _PaletteTile(kind: entry.key),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  final String kind;
  const _PaletteTile({required this.kind});

  static const _icons = <String, IconData>{
    'gauge': Icons.speed,
    'bar': Icons.bar_chart,
    'text': Icons.text_fields,
    'chart': Icons.show_chart,
    'status': Icons.info_outline,
    'image': Icons.image,
    'web': Icons.public,
    'paint': Icons.brush,
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(_icons[kind] ?? Icons.widgets),
        title: Text(kind),
        dense: true,
      ),
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
                    final id = ref.read(idGeneratorProvider).next();
                    final localPos = _toCanvasPosition(details.offset);
                    final node = CanvasNode(
                      id: id,
                      transform: NodeTransforms.compose(translation: localPos),
                      data: WidgetInstance(
                        id: id,
                        kind: kind,
                        properties: _defaultProperties(kind),
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
        for (final entry in widget.properties.entries)
          if (entry.key != 'program')
            _BindingField(node: node, widget: widget, name: entry.key, binding: entry.value),
      ];
    }

    final all = allProperties(widget.kind);
    final basic = all.where((m) => m.minLevel == CapabilityLevel.basic).toList();
    final advanced = all.where((m) => m.minLevel == CapabilityLevel.advanced).toList();
    final expert = all.where((m) => m.minLevel == CapabilityLevel.expert).toList();
    final entries = Map<String, Binding>.from(widget.properties);

    return [
      for (final m in basic)
        if (entries.containsKey(m.key))
          _BindingField(node: node, widget: widget, name: m.key, binding: entries[m.key]!),
      if (advanced.isNotEmpty)
        _ExpandableSection(
          title: 'Advanced',
          initiallyExpanded: true,
          children: [
            for (final m in advanced)
              if (entries.containsKey(m.key))
                _BindingField(node: node, widget: widget, name: m.key, binding: entries[m.key]!),
          ],
        ),
      if (expert.isNotEmpty)
        _ExpandableSection(
          title: 'Expert',
          initiallyExpanded: false,
          children: [
            for (final m in expert)
              if (entries.containsKey(m.key))
                _BindingField(node: node, widget: widget, name: m.key, binding: entries[m.key]!),
          ],
        ),
    ];
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
