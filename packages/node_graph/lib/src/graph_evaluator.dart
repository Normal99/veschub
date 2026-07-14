/// Topological graph evaluator.
///
/// Evaluates a [FlowGraph] by:
///  1. Topologically sorting nodes (sources first).
///  2. For each node, gathering input values from connected edges.
///  3. Calling the node kind's [evaluate] function.
///  4. Collecting output-node values as the graph's named outputs.
///
/// Telemetry values are read via a callback so the evaluator is pure and
/// testable without a live [TelemetryStore].
library;

import 'graph_model.dart';
import 'node_catalog.dart';

/// A cycle was detected in the graph.
class GraphCycleException implements Exception {
  final String message;
  GraphCycleException(this.message);
  @override
  String toString() => 'GraphCycleException: $message';
}

/// Evaluates [graph] and returns a map of output-node-id → resolved value.
///
/// [telemetry] provides values for telemetry-input nodes by canonical key.
/// Node properties (e.g. the telemetry key for a `telemetry` node, the op for
/// a `math` node) are passed via the [properties] map: `nodeId` → `propName` → value.
Map<String, dynamic> evaluateGraph(
  FlowGraph graph, {
  required dynamic Function(String key) telemetry,
  Map<String, Map<String, dynamic>> properties = const {},
}) {
  // 1. Topological sort via Kahn's algorithm.
  final sorted = _topologicalSort(graph);

  // 2. Evaluate each node in order, storing outputs.
  // outputs: nodeId → socketId → value
  final outputs = <String, Map<String, dynamic>>{};
  final graphOutputs = <String, dynamic>{};

  for (final node in sorted) {
    final def = builtInNodeKinds[node.kind];
    if (def == null) continue;

    // Gather inputs from edges + properties.
    final inputValues = <String, dynamic>{};
    // Properties take precedence as defaults (e.g. literal value, op string).
    final nodeProps = properties[node.id] ?? const {};
    inputValues.addAll(nodeProps);

    // Override with edge-connected values where present.
    for (final socket in node.inputs) {
      final incomingEdges = graph.incoming(node.id, socket.id);
      for (final edge in incomingEdges) {
        final sourceOut = outputs[edge.sourceNode];
        if (sourceOut != null && sourceOut.containsKey(edge.sourceSocket)) {
          inputValues[socket.id] = sourceOut[edge.sourceSocket];
        }
      }
    }

    final ctx = NodeEvalContext(inputs: inputValues, telemetry: telemetry);
    final result = def.evaluate(ctx);
    outputs[node.id] = result;

    // Output nodes produce the graph's named outputs.
    if (node.kind == 'output') {
      final outputName = nodeProps['name'] as String? ?? node.id;
      graphOutputs[outputName] = inputValues['value'];
    }
  }

  return graphOutputs;
}

/// Kahn's algorithm topological sort. Throws [GraphCycleException] on cycles.
List<GraphNode> _topologicalSort(FlowGraph graph) {
  // Build adjacency: sourceNode → list of targetNodes it feeds.
  final adjacency = <String, List<String>>{};
  final inDegree = <String, int>{};
  for (final node in graph.nodes) {
    adjacency[node.id] = [];
    inDegree[node.id] = 0;
  }
  for (final edge in graph.edges) {
    adjacency[edge.sourceNode]?.add(edge.targetNode);
    inDegree[edge.targetNode] = (inDegree[edge.targetNode] ?? 0) + 1;
  }

  // Start with nodes that have no incoming edges.
  final queue = <String>[
    for (final node in graph.nodes)
      if ((inDegree[node.id] ?? 0) == 0) node.id,
  ];
  // Preserve original node order for stable sorting.
  queue.sort((a, b) {
    final ia = graph.nodes.indexWhere((n) => n.id == a);
    final ib = graph.nodes.indexWhere((n) => n.id == b);
    return ia.compareTo(ib);
  });

  final sorted = <GraphNode>[];
  while (queue.isNotEmpty) {
    final id = queue.removeAt(0);
    final node = graph.node(id);
    if (node != null) sorted.add(node);

    for (final target in adjacency[id] ?? <String>[]) {
      inDegree[target] = (inDegree[target] ?? 1) - 1;
      if (inDegree[target] == 0) queue.add(target);
    }
  }

  if (sorted.length != graph.nodes.length) {
    final remaining = graph.nodes
        .where((n) => !sorted.any((s) => s.id == n.id))
        .map((n) => n.id)
        .toList();
    throw GraphCycleException(
      'Cycle detected involving nodes: ${remaining.join(', ')}',
    );
  }

  return sorted;
}
