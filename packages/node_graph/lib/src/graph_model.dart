/// Node model for the dataflow graph.
///
/// A [GraphNode] has typed input/output [Socket]s and a [kind] that determines
/// how it evaluates. Connections ([GraphEdge]) link an output socket to an
/// input socket. The graph is evaluated topologically by [GraphEvaluator].
library;

import 'graph_point.dart';

/// A typed input or output socket on a node.
class Socket {
  final String id;
  final String label;
  final SocketType type;

  const Socket({
    required this.id,
    required this.label,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type.name,
      };

  factory Socket.fromJson(Map<String, dynamic> json) => Socket(
        id: json['id'] as String,
        label: json['label'] as String,
        type: SocketType.values.byName(json['type'] as String),
      );
}

enum SocketType { number, boolean, string, any }

/// A single node in the dataflow graph.
class GraphNode {
  final String id;
  final String kind;
  final GraphPoint position;
  final List<Socket> inputs;
  final List<Socket> outputs;

  const GraphNode({
    required this.id,
    required this.kind,
    required this.position,
    required this.inputs,
    required this.outputs,
  });

  GraphNode copyWith({
    String? id,
    String? kind,
    GraphPoint? position,
    List<Socket>? inputs,
    List<Socket>? outputs,
  }) =>
      GraphNode(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        position: position ?? this.position,
        inputs: inputs ?? this.inputs,
        outputs: outputs ?? this.outputs,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'position': [position.x, position.y],
        'inputs': inputs.map((s) => s.toJson()).toList(),
        'outputs': outputs.map((s) => s.toJson()).toList(),
      };

  factory GraphNode.fromJson(Map<String, dynamic> json) => GraphNode(
        id: json['id'] as String,
        kind: json['kind'] as String,
        position: GraphPoint(
          (json['position'] as List).first as double,
          (json['position'] as List).last as double,
        ),
        inputs: (json['inputs'] as List)
            .map((s) => Socket.fromJson(s as Map<String, dynamic>))
            .toList(),
        outputs: (json['outputs'] as List)
            .map((s) => Socket.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// A connection from a source node's output to a target node's input.
class GraphEdge {
  final String sourceNode;
  final String sourceSocket;
  final String targetNode;
  final String targetSocket;

  const GraphEdge({
    required this.sourceNode,
    required this.sourceSocket,
    required this.targetNode,
    required this.targetSocket,
  });

  Map<String, dynamic> toJson() => {
        'source_node': sourceNode,
        'source_socket': sourceSocket,
        'target_node': targetNode,
        'target_socket': targetSocket,
      };

  factory GraphEdge.fromJson(Map<String, dynamic> json) => GraphEdge(
        sourceNode: json['source_node'] as String,
        sourceSocket: json['source_socket'] as String,
        targetNode: json['target_node'] as String,
        targetSocket: json['target_socket'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GraphEdge &&
          sourceNode == other.sourceNode &&
          sourceSocket == other.sourceSocket &&
          targetNode == other.targetNode &&
          targetSocket == other.targetSocket;

  @override
  int get hashCode =>
      Object.hash(sourceNode, sourceSocket, targetNode, targetSocket);
}

/// The full dataflow graph.
class FlowGraph {
  final String id;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  const FlowGraph({
    required this.id,
    required this.nodes,
    required this.edges,
  });

  FlowGraph copyWith({
    String? id,
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
  }) =>
      FlowGraph(
        id: id ?? this.id,
        nodes: nodes ?? this.nodes,
        edges: edges ?? this.edges,
      );

  GraphNode? node(String id) {
    final i = nodes.indexWhere((n) => n.id == id);
    return i >= 0 ? nodes[i] : null;
  }

  /// Returns the edges feeding into [targetNode].[targetSocket].
  List<GraphEdge> incoming(String targetNode, String targetSocket) => edges
      .where(
        (e) => e.targetNode == targetNode && e.targetSocket == targetSocket,
      )
      .toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };

  factory FlowGraph.fromJson(Map<String, dynamic> json) => FlowGraph(
        id: json['id'] as String,
        nodes: (json['nodes'] as List)
            .map((n) => GraphNode.fromJson(n as Map<String, dynamic>))
            .toList(),
        edges: (json['edges'] as List)
            .map((e) => GraphEdge.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static FlowGraph empty(String id) =>
      FlowGraph(id: id, nodes: const [], edges: const []);
}
