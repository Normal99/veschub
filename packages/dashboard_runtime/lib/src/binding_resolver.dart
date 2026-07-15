/// Resolves a [Binding] to a concrete value using a [TelemetryStore].
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:node_graph/node_graph.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

import 'formula_evaluator.dart';

/// Result of resolving a binding.
class ResolvedValue {
  final dynamic value;
  final bool isResolved;

  const ResolvedValue(this.value, {this.isResolved = true});
  const ResolvedValue.unresolved()
      : value = null,
        isResolved = false;
}

/// Optional graph registry: maps a graph id → deserialized [FlowGraph] + node
/// properties. The runtime builds this from the document's `graphs` field.
class GraphRegistry {
  final Map<String, FlowGraph> graphs;
  final Map<String, Map<String, Map<String, dynamic>>> properties;

  const GraphRegistry({
    this.graphs = const {},
    this.properties = const {},
  });

  static const empty = GraphRegistry();

  static GraphRegistry fromDocument(DashboardDocument doc) {
    final graphs = <String, FlowGraph>{};
    final props = <String, Map<String, Map<String, dynamic>>>{};
    for (final entry in doc.graphs.entries) {
      try {
        final g = FlowGraph.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        graphs[entry.key] = g;
        // Extract per-node properties if present under 'properties'.
        final rawProps = (entry.value as Map)['properties'];
        if (rawProps is Map) {
          props[entry.key] = rawProps.map(
            (k, v) => MapEntry(
              k.toString(),
              Map<String, dynamic>.from(v as Map),
            ),
          );
        }
      } catch (_) {
        // Skip malformed graphs.
      }
    }
    return GraphRegistry(graphs: graphs, properties: props);
  }
}

/// Resolves [binding] against [store] and optional [graphs].
ResolvedValue resolveBinding(
  Binding binding,
  TelemetryStore store, {
  GraphRegistry graphs = GraphRegistry.empty,
}) {
  return binding.map(
    literal: (b) => ResolvedValue(b.value),
    telemetry: (b) {
      if (!store.contains(b.key)) return const ResolvedValue.unresolved();
      return ResolvedValue(store.value(b.key));
    },
    graph: (b) {
      final graph = graphs.graphs[b.graphId];
      if (graph == null) return const ResolvedValue.unresolved();
      try {
        final result = evaluateGraph(
          graph,
          telemetry: (key) => store.value(key),
          properties: graphs.properties[b.graphId] ?? const {},
        );
        final v = result[b.output];
        if (v == null) return const ResolvedValue.unresolved();
        return ResolvedValue(v);
      } catch (_) {
        return const ResolvedValue.unresolved();
      }
    },
    formula: (b) {
      try {
        final v = evaluateFormula(b.expression, (key) {
          final val = store.value(key);
          if (val is num) return val;
          return null;
        });
        return ResolvedValue(v);
      } catch (_) {
        return const ResolvedValue.unresolved();
      }
    },
  );
}
