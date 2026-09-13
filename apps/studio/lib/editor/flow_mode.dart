/// Flow mode (Expert) — the dataflow graph editor.
///
/// Users build a [FlowGraph] by dragging nodes from a palette, connecting
/// sockets, and setting node properties. The graph is evaluated by
/// [evaluateGraph] at render time; the result feeds [Binding.graph] properties.
library;

import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:node_graph/node_graph.dart';
import 'package:node_graph_editor/node_graph_editor.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/editor_providers.dart';

class FlowMode extends ConsumerWidget {
  const FlowMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(flowGraphProvider);
    final properties = ref.watch(flowPropertiesProvider);
    final selected = ref.watch(selectedNodeProvider);

    return Row(
      children: [
        const _NodePalette(),
        Expanded(
          child: Column(
            children: [
              _FlowToolbar(graph: graph),
              Expanded(
                child: NodeEditor(
                  graph: graph,
                  properties: properties,
                  selectedNodeId: selected,
                  onNodeSelected: (id) =>
                      ref.read(selectedNodeProvider.notifier).state = id,
                  onChanged: (g) =>
                      ref.read(flowGraphProvider.notifier).state = g,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 280, child: _NodePropertiesPanel()),
      ],
    );
  }
}

class _FlowToolbar extends ConsumerWidget {
  final FlowGraph graph;
  const _FlowToolbar({required this.graph});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Text('${graph.nodes.length} nodes · ${graph.edges.length} edges'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.download, size: 18),
            tooltip: 'Export graph as a reusable .flowgraph.json preset',
            onPressed: () => _exportGraph(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, size: 18),
            tooltip: 'Import a .flowgraph.json preset (replaces this graph)',
            onPressed: () => _importGraph(context, ref),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.save, size: 16),
            label: const Text('Save graph'),
            onPressed: () => _saveToDocument(context, ref),
          ),
        ],
      ),
    );
  }

  /// Exports the current graph + its node properties as a standalone file —
  /// independent of "Save graph" (which embeds it in the dashboard document)
  /// so a graph can be reused as a preset across different dashboards.
  Future<void> _exportGraph(BuildContext context, WidgetRef ref) async {
    final graph = ref.read(flowGraphProvider);
    final properties = ref.read(flowPropertiesProvider);
    final serialized = graph.toJson();
    serialized['properties'] = properties;
    final json = const JsonEncoder.withIndent('  ').convert(serialized);
    final dir = await getApplicationDocumentsDirectory();
    final safeName =
        graph.id.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/$safeName.flowgraph.json');
    try {
      await file.writeAsString(json);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importGraph(BuildContext context, WidgetRef ref) async {
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
      final importedGraph = FlowGraph.fromJson(json);
      final importedProps = json['properties'];
      ref.read(flowGraphProvider.notifier).state = importedGraph;
      ref.read(flowPropertiesProvider.notifier).state = importedProps is Map
          ? importedProps.map(
              (k, v) =>
                  MapEntry(k as String, Map<String, dynamic>.from(v as Map)),
            )
          : const {};
      ref.read(selectedNodeProvider.notifier).state = null;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported "${importedGraph.id}": ${importedGraph.nodes.length} '
              'nodes, ${importedGraph.edges.length} edges. Replaces the '
              'current graph — "Save graph" to keep it.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  void _saveToDocument(BuildContext context, WidgetRef ref) {
    final graph = ref.read(flowGraphProvider);
    final properties = ref.read(flowPropertiesProvider);
    final serialized = graph.toJson();
    serialized['properties'] = properties;
    final graphs = Map<String, dynamic>.from(ref.read(flowGraphsProvider));
    graphs[graph.id] = serialized;
    ref.read(flowGraphsProvider.notifier).state = graphs;
    ref.read(isDirtyProvider.notifier).state = true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Graph ready: ${graph.nodes.length} nodes, ${graph.edges.length} edges. '
          'Save the dashboard to persist.',
        ),
      ),
    );
  }
}

class _NodePalette extends ConsumerWidget {
  const _NodePalette();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 160,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child:
                Text('Blocks', style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: ListView(
              children: [
                for (final def in builtInNodeKinds.values)
                  Draggable<String>(
                    key: ValueKey(def.kind),
                    data: def.kind,
                    feedback: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          def.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: Icon(_iconFor(def.kind), size: 18),
                        title: Text(def.displayName,
                            style: const TextStyle(fontSize: 13)),
                        dense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'telemetry' => Icons.sensors,
        'literal' => Icons.data_object,
        'math' => Icons.calculate,
        'compare' => Icons.compare_arrows,
        'conditional' => Icons.alt_route,
        'clamp' => Icons.compress,
        'mapRange' => Icons.open_in_full,
        'output' => Icons.outlet,
        _ => Icons.extension,
      };
}

class _NodePropertiesPanel extends ConsumerWidget {
  const _NodePropertiesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(flowGraphProvider);
    final properties = ref.watch(flowPropertiesProvider);
    final selected = ref.watch(selectedNodeProvider);

    if (selected == null) {
      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade300)),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select a node to edit its properties',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final node = graph.node(selected);
    if (node == null) return const SizedBox.shrink();
    final props = properties[selected] ?? const <String, dynamic>{};
    final def = builtInNodeKinds[node.kind];

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Node properties',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _Field(label: 'ID', value: node.id),
          _Field(label: 'Kind', value: node.kind),
          if (def != null) _Field(label: 'Name', value: def.displayName),
          const Divider(),
          // Kind-specific property editors.
          ..._propertyEditors(node, props, ref),
          const Divider(),
          TextButton.icon(
            // Matches Canvas mode's "Delete widget" button in
            // studio_inspector.dart — same action, same icon weight.
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Delete node'),
            onPressed: () {
              final newNodes =
                  graph.nodes.where((n) => n.id != selected).toList();
              final newEdges = graph.edges
                  .where((e) =>
                      e.sourceNode != selected && e.targetNode != selected)
                  .toList();
              ref.read(flowGraphProvider.notifier).state =
                  graph.copyWith(nodes: newNodes, edges: newEdges);
              ref.read(selectedNodeProvider.notifier).state = null;
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _propertyEditors(
    GraphNode node,
    Map<String, dynamic> props,
    WidgetRef ref,
  ) {
    switch (node.kind) {
      case 'telemetry':
        return [
          _TextPropEditor(
            label: 'Telemetry key',
            value: props['key'] as String? ?? '',
            onChanged: (v) => _setProp(ref, node.id, 'key', v),
          ),
        ];
      case 'literal':
        return [
          _TextPropEditor(
            label: 'Value',
            value: props['value']?.toString() ?? '',
            onChanged: (v) {
              final n = num.tryParse(v) ?? v;
              _setProp(ref, node.id, 'value', n);
            },
          ),
        ];
      case 'math':
        return [
          _DropdownPropEditor(
            label: 'Operation',
            value: props['op'] as String? ?? 'add',
            options: const ['add', 'sub', 'mul', 'div', 'mod', 'pow'],
            onChanged: (v) => _setProp(ref, node.id, 'op', v),
          ),
        ];
      case 'compare':
        return [
          _DropdownPropEditor(
            label: 'Comparison',
            value: props['op'] as String? ?? 'lt',
            options: const ['lt', 'lte', 'gt', 'gte', 'eq', 'neq'],
            onChanged: (v) => _setProp(ref, node.id, 'op', v),
          ),
        ];
      case 'output':
        return [
          _TextPropEditor(
            label: 'Output name',
            value: props['name'] as String? ?? node.id,
            onChanged: (v) => _setProp(ref, node.id, 'name', v),
          ),
        ];
      // conditional, clamp, mapRange: all inputs arrive via edges, not props.
      default:
        return [];
    }
  }

  void _setProp(WidgetRef ref, String nodeId, String key, dynamic value) {
    final current = Map<String, Map<String, dynamic>>.from(
      ref.read(flowPropertiesProvider),
    );
    final nodeProps = Map<String, dynamic>.from(current[nodeId] ?? const {});
    nodeProps[key] = value;
    current[nodeId] = nodeProps;
    ref.read(flowPropertiesProvider.notifier).state = current;
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

class _TextPropEditor extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _TextPropEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: TextFormField(
              initialValue: value,
              decoration: const InputDecoration(isDense: true),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownPropEditor extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _DropdownPropEditor({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => v != null ? onChanged(v) : null,
            ),
          ),
        ],
      ),
    );
  }
}
