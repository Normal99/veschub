/// The studio editor screen: toolbar + palette + canvas + properties inspector.
///
/// This is the Phase 3 "editor that finally works" — drag-drop widgets from
/// the palette onto the [EditorCanvas], move/snap them with alignment guides,
/// edit bound properties in the inspector, and save/load to drift.
library;

import 'dart:convert';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paint_dsl/paint_dsl.dart';
import 'package:widgets_library/widgets_library.dart';

import '../document_bridge.dart';
import '../providers/editor_providers.dart';
import 'flow_mode.dart';
import 'template_mode.dart';

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
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
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
              const SizedBox(
                width: 280,
                child: _PropertiesInspector(),
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
                          final doc = db.decodeDocument(e);
                          final scene = ref.read(sceneModelProvider);
                          sceneFromDocument(scene, doc);
                          ref.read(dashboardNameProvider.notifier).state =
                              e.name;
                          ref
                              .read(dashboardDescriptionProvider.notifier)
                              .state = doc.description;
                          ref.read(dashboardIdProvider.notifier).state = e.id;
                          ref.read(commandStackProvider).clear();
                          ref.read(isDirtyProvider.notifier).state = false;
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.widgets),
        title: Text(kind),
        dense: true,
      ),
    );
  }
}

/// The canvas area with drag-drop acceptance.
class _CanvasArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);
    final commands = ref.watch(commandStackProvider);

    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        final kind = details.data['kind'] as String;
        final id = ref.read(idGeneratorProvider).next();
        final node = CanvasNode(
          id: id,
          transform: NodeTransforms.compose(
            translation: details.offset,
          ),
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
        return Container(
          color: candidate.isNotEmpty
              ? Colors.blue.withValues(alpha: 0.05)
              : Theme.of(context).colorScheme.surface,
          child: EditorCanvas(
            scene: scene,
            selection: selection,
            commands: commands,
            nodeBuilder: (node) {
              final w = node.data as WidgetInstance?;
              if (w == null) {
                return const Center(child: Text('No data'));
              }
              return buildWidget(w, const {});
            },
            nodeWidth: (_) => kDefaultNodeWidth,
            nodeHeight: (_) => kDefaultNodeHeight,
          ),
        );
      },
    );
  }

  Map<String, Binding> _defaultProperties(String kind) {
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
          Text('Properties', style: Theme.of(context).textTheme.titleSmall),
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
            if (widget.kind == 'paint') ...[
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
                  _BindingField(name: entry.key, binding: entry.value),
            ] else
              for (final entry in widget.properties.entries)
                if (visibleProperties(widget.kind, level)
                    .any((m) => m.key == entry.key))
                  _BindingField(
                    name: entry.key,
                    binding: entry.value,
                  ),
          ],
        ],
      ),
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

class _BindingField extends StatelessWidget {
  final String name;
  final Binding binding;
  const _BindingField({required this.name, required this.binding});

  @override
  Widget build(BuildContext context) {
    final desc = binding.map(
      literal: (b) => 'Literal: ${b.value}',
      telemetry: (b) => 'Telemetry: ${b.key}',
      graph: (b) => 'Graph: ${b.graphId}.${b.output}',
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(desc,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
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
