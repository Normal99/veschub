import 'package:test/test.dart';
import 'package:node_graph/node_graph.dart';

FlowGraph _simpleMathGraph() {
  return const FlowGraph(
    id: 'g1',
    nodes: [
      GraphNode(
        id: 'tel',
        kind: 'telemetry',
        position: GraphPoint(0, 0),
        inputs: [],
        outputs: [
          Socket(id: 'value', label: 'Value', type: SocketType.any),
        ],
      ),
      GraphNode(
        id: 'lit',
        kind: 'literal',
        position: GraphPoint(0, 100),
        inputs: [
          Socket(id: 'value', label: 'Value', type: SocketType.any),
        ],
        outputs: [
          Socket(id: 'value', label: 'Value', type: SocketType.any),
        ],
      ),
      GraphNode(
        id: 'math',
        kind: 'math',
        position: GraphPoint(200, 50),
        inputs: [
          Socket(id: 'a', label: 'A', type: SocketType.number),
          Socket(id: 'b', label: 'B', type: SocketType.number),
          Socket(id: 'op', label: 'Op', type: SocketType.string),
        ],
        outputs: [
          Socket(id: 'result', label: 'Result', type: SocketType.number),
        ],
      ),
      GraphNode(
        id: 'out',
        kind: 'output',
        position: GraphPoint(400, 50),
        inputs: [
          Socket(id: 'value', label: 'Value', type: SocketType.any),
        ],
        outputs: [],
      ),
    ],
    edges: [
      GraphEdge(
        sourceNode: 'tel',
        sourceSocket: 'value',
        targetNode: 'math',
        targetSocket: 'a',
      ),
      GraphEdge(
        sourceNode: 'lit',
        sourceSocket: 'value',
        targetNode: 'math',
        targetSocket: 'b',
      ),
      GraphEdge(
        sourceNode: 'math',
        sourceSocket: 'result',
        targetNode: 'out',
        targetSocket: 'value',
      ),
    ],
  );
}

void main() {
  group('FlowGraph serialization', () {
    test('round-trips through JSON', () {
      final g = _simpleMathGraph();
      final json = g.toJson();
      final decoded = FlowGraph.fromJson(json);

      expect(decoded.id, 'g1');
      expect(decoded.nodes, hasLength(4));
      expect(decoded.edges, hasLength(3));
      expect(decoded.nodes.first.kind, 'telemetry');
      expect(decoded.edges.first.sourceNode, 'tel');
    });
  });

  group('evaluateGraph', () {
    test('math add: telemetry(1000) + literal(200) = 1200', () {
      final g = _simpleMathGraph();
      final result = evaluateGraph(
        g,
        telemetry: (key) => 1000,
        properties: {
          'tel': {'key': 'erpm'},
          'lit': {'value': 200},
          'math': {'op': 'add'},
          'out': {'name': 'result'},
        },
      );
      expect(result['result'], 1200);
    });

    test('math mul: telemetry(50) * literal(2) = 100', () {
      final g = _simpleMathGraph();
      final result = evaluateGraph(
        g,
        telemetry: (key) => 50,
        properties: {
          'tel': {'key': 'v_in'},
          'lit': {'value': 2},
          'math': {'op': 'mul'},
          'out': {'name': 'result'},
        },
      );
      expect(result['result'], 100);
    });

    test('clamp node clamps to range', () {
      const g = FlowGraph(
        id: 'clamp',
        nodes: [
          GraphNode(
            id: 'lit',
            kind: 'literal',
            position: GraphPoint.zero,
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
            outputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
          ),
          GraphNode(
            id: 'clamp',
            kind: 'clamp',
            position: GraphPoint(200, 0),
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.number),
              Socket(id: 'min', label: 'Min', type: SocketType.number),
              Socket(id: 'max', label: 'Max', type: SocketType.number),
            ],
            outputs: [
              Socket(id: 'result', label: 'R', type: SocketType.number),
            ],
          ),
          GraphNode(
            id: 'out',
            kind: 'output',
            position: GraphPoint(400, 0),
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
            outputs: [],
          ),
        ],
        edges: [
          GraphEdge(
            sourceNode: 'lit',
            sourceSocket: 'value',
            targetNode: 'clamp',
            targetSocket: 'value',
          ),
          GraphEdge(
            sourceNode: 'clamp',
            sourceSocket: 'result',
            targetNode: 'out',
            targetSocket: 'value',
          ),
        ],
      );
      final result = evaluateGraph(
        g,
        telemetry: (_) => null,
        properties: {
          'lit': {'value': 150},
          'clamp': {'min': 0, 'max': 100},
          'out': {'name': 'clamped'},
        },
      );
      expect(result['clamped'], 100);
    });

    test('conditional: true → trueValue', () {
      const g = FlowGraph(
        id: 'cond',
        nodes: [
          GraphNode(
            id: 'cmp',
            kind: 'compare',
            position: GraphPoint.zero,
            inputs: [
              Socket(id: 'a', label: 'A', type: SocketType.any),
              Socket(id: 'b', label: 'B', type: SocketType.any),
              Socket(id: 'op', label: 'Op', type: SocketType.string),
            ],
            outputs: [
              Socket(id: 'result', label: 'R', type: SocketType.boolean),
            ],
          ),
          GraphNode(
            id: 'cond',
            kind: 'conditional',
            position: GraphPoint(200, 0),
            inputs: [
              Socket(id: 'condition', label: 'C', type: SocketType.boolean),
              Socket(id: 'trueValue', label: 'T', type: SocketType.any),
              Socket(id: 'falseValue', label: 'F', type: SocketType.any),
            ],
            outputs: [
              Socket(id: 'result', label: 'R', type: SocketType.any),
            ],
          ),
          GraphNode(
            id: 'out',
            kind: 'output',
            position: GraphPoint(400, 0),
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
            outputs: [],
          ),
        ],
        edges: [
          GraphEdge(
            sourceNode: 'cmp',
            sourceSocket: 'result',
            targetNode: 'cond',
            targetSocket: 'condition',
          ),
          GraphEdge(
            sourceNode: 'cond',
            sourceSocket: 'result',
            targetNode: 'out',
            targetSocket: 'value',
          ),
        ],
      );
      final result = evaluateGraph(
        g,
        telemetry: (_) => null,
        properties: {
          'cmp': {'a': 50, 'b': 30, 'op': 'gt'},
          'cond': {'trueValue': 'fast', 'falseValue': 'slow'},
          'out': {'name': 'speed'},
        },
      );
      expect(result['speed'], 'fast');
    });

    test('mapRange maps 0..100 → 0..1', () {
      const g = FlowGraph(
        id: 'map',
        nodes: [
          GraphNode(
            id: 'lit',
            kind: 'literal',
            position: GraphPoint.zero,
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
            outputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
          ),
          GraphNode(
            id: 'map',
            kind: 'mapRange',
            position: GraphPoint(200, 0),
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.number),
              Socket(id: 'inMin', label: 'IMin', type: SocketType.number),
              Socket(id: 'inMax', label: 'IMax', type: SocketType.number),
              Socket(id: 'outMin', label: 'OMin', type: SocketType.number),
              Socket(id: 'outMax', label: 'OMax', type: SocketType.number),
            ],
            outputs: [
              Socket(id: 'result', label: 'R', type: SocketType.number),
            ],
          ),
          GraphNode(
            id: 'out',
            kind: 'output',
            position: GraphPoint(400, 0),
            inputs: [
              Socket(id: 'value', label: 'V', type: SocketType.any),
            ],
            outputs: [],
          ),
        ],
        edges: [
          GraphEdge(
            sourceNode: 'lit',
            sourceSocket: 'value',
            targetNode: 'map',
            targetSocket: 'value',
          ),
          GraphEdge(
            sourceNode: 'map',
            sourceSocket: 'result',
            targetNode: 'out',
            targetSocket: 'value',
          ),
        ],
      );
      final result = evaluateGraph(
        g,
        telemetry: (_) => null,
        properties: {
          'lit': {'value': 75},
          'map': {'inMin': 0, 'inMax': 100, 'outMin': 0, 'outMax': 1},
          'out': {'name': 'mapped'},
        },
      );
      expect(result['mapped'], closeTo(0.75, 1e-9));
    });

    test('throws on cycle', () {
      const g = FlowGraph(
        id: 'cycle',
        nodes: [
          GraphNode(
            id: 'a',
            kind: 'math',
            position: GraphPoint.zero,
            inputs: [
              Socket(id: 'a', label: 'A', type: SocketType.number),
              Socket(id: 'b', label: 'B', type: SocketType.number),
              Socket(id: 'op', label: 'Op', type: SocketType.string),
            ],
            outputs: [
              Socket(id: 'result', label: 'R', type: SocketType.number),
            ],
          ),
          GraphNode(
            id: 'b',
            kind: 'math',
            position: GraphPoint(200, 0),
            inputs: [
              Socket(id: 'a', label: 'A', type: SocketType.number),
              Socket(id: 'b', label: 'B', type: SocketType.number),
              Socket(id: 'op', label: 'Op', type: SocketType.string),
            ],
            outputs: [
              Socket(id: 'result', label: 'R', type: SocketType.number),
            ],
          ),
        ],
        edges: [
          GraphEdge(
            sourceNode: 'a',
            sourceSocket: 'result',
            targetNode: 'b',
            targetSocket: 'a',
          ),
          GraphEdge(
            sourceNode: 'b',
            sourceSocket: 'result',
            targetNode: 'a',
            targetSocket: 'b',
          ),
        ],
      );
      expect(
        () => evaluateGraph(g, telemetry: (_) => null),
        throwsA(isA<GraphCycleException>()),
      );
    });
  });
}
