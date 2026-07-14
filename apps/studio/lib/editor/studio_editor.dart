/// The studio editor screen: toolbar + palette + canvas + properties inspector.
///
/// This is the Phase 3 "editor that finally works" — drag-drop widgets from
/// the palette onto the [EditorCanvas], move/snap them with alignment guides,
/// edit bound properties in the inspector, and save/load to drift.
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgets_library/widgets_library.dart';

import '../document_bridge.dart';
import '../providers/editor_providers.dart';

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
      body: mode == EditorMode.template
          ? const _TemplateModePlaceholder()
          : Row(
              children: [
                const _WidgetPalette(),
                Expanded(child: _CanvasArea()),
                const SizedBox(
                  width: 280,
                  child: _PropertiesInspector(),
                ),
              ],
            ),
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final scene = ref.read(sceneModelProvider);
    final name = ref.read(dashboardNameProvider);
    final db = ref.read(dashboardDatabaseProvider);
    final existingId = ref.read(dashboardIdProvider);

    final doc = documentFromScene(scene: scene, name: name);
    try {
      int id;
      if (existingId != null) {
        await db.updateDocument(existingId, doc);
        id = existingId;
      } else {
        id = await db.saveDashboard(name, doc);
      }
      ref.read(dashboardIdProvider.notifier).state = id;
      ref.read(isDirtyProvider.notifier).state = false;
      ref.invalidate(recentDashboardsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved "$name"')),
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
                      return ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: Text(e.name),
                        subtitle: Text('Updated ${e.updatedAt.toLocal()}'),
                        onTap: () {
                          final doc = db.decodeDocument(e);
                          final scene = ref.read(sceneModelProvider);
                          sceneFromDocument(scene, doc);
                          ref.read(dashboardNameProvider.notifier).state =
                              e.name;
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
            const Divider(),
            for (final entry in widget.properties.entries)
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

class _TemplateModePlaceholder extends StatelessWidget {
  const _TemplateModePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.dashboard_customize, size: 64),
          SizedBox(height: 16),
          Text('Template mode',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Starter templates + Basic-mode editing arrive in Phase 5.'),
        ],
      ),
    );
  }
}
