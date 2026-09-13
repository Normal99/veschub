// node_graph_editor had zero test coverage — 462 lines of interactive Flow
// mode canvas code (drag nodes, connect sockets, delete edges, drag-drop
// from a palette) with nothing verifying any of it worked. This drives the
// real NodeEditor widget through WidgetTester the way flow_mode.dart's
// actual palette does (a Draggable<String> carrying a node kind onto the
// NodeEditor's DragTarget<String>), not by calling internal methods.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:node_graph/node_graph.dart';
import 'package:node_graph_editor/node_graph_editor.dart';

/// A minimal host mirroring how flow_mode.dart wires NodeEditor: owns the
/// FlowGraph, applies onChanged, and offers a palette of Draggable<String>
/// node-kind sources exactly like the real palette does.
class _Harness extends StatefulWidget {
  final FlowGraph initial;
  final ValueChanged<String>? onNodeSelected;
  final String? selectedNodeId;
  const _Harness({
    required this.initial,
    this.onNodeSelected,
    this.selectedNodeId,
  });

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  late FlowGraph graph = widget.initial;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 120,
              child: Column(
                children: [
                  for (final def in builtInNodeKinds.values)
                    Draggable<String>(
                      key: ValueKey('palette_${def.kind}'),
                      data: def.kind,
                      feedback: Material(child: Text(def.displayName)),
                      child: SizedBox(
                        height: 32,
                        child: Text(def.displayName),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: NodeEditor(
                graph: graph,
                onChanged: (g) => setState(() => graph = g),
                onNodeSelected: widget.onNodeSelected,
                selectedNodeId: widget.selectedNodeId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Finder _onCanvas(String text) =>
    find.descendant(of: find.byType(NodeEditor), matching: find.text(text));

void main() {
  testWidgets('dropping a palette node adds it to the graph at the drop point',
      (tester) async {
    await tester.pumpWidget(_Harness(initial: FlowGraph.empty('g1')));
    await tester.pumpAndSettle();

    expect(_onCanvas('Constant'), findsNothing);

    final source = find.byKey(const ValueKey('palette_literal'));
    final target = find.byType(NodeEditor);
    await tester.drag(
        source, tester.getCenter(target) - tester.getCenter(source));
    await tester.pumpAndSettle();

    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.graph.nodes, hasLength(1));
    expect(state.graph.nodes.single.kind, 'literal');
    // A node card for "Constant" now exists on the canvas too.
    expect(_onCanvas('Constant'), findsOneWidget);
  });

  testWidgets('dragging a node updates its position via onChanged',
      (tester) async {
    final graph = FlowGraph(
      id: 'g1',
      nodes: const [
        GraphNode(
          id: 'n1',
          kind: 'literal',
          position: GraphPoint(50, 50),
          inputs: [],
          outputs: [Socket(id: 'out', label: 'Value', type: SocketType.number)],
        ),
      ],
      edges: const [],
    );
    await tester.pumpWidget(_Harness(initial: graph));
    await tester.pumpAndSettle();
    final state = tester.state<_HarnessState>(find.byType(_Harness));

    // tester.drag() subdivides the requested offset into a couple of
    // pointer-move steps, and the pan recognizer consumes part of the
    // first step's movement establishing touch-slop before it starts
    // reporting deltas — so the total *reported* movement is somewhat
    // less than the full requested distance. Request a large, clearly
    // diagonal move and assert the direction and rough magnitude rather
    // than an exact endpoint, which would depend on that internal,
    // undocumented slop-consumption behavior.
    await tester.drag(_onCanvas('Constant'), const Offset(200, 100));
    await tester.pumpAndSettle();

    final moved = state.graph.node('n1')!.position;
    expect(moved.x, greaterThan(50 + 100)); // at least half the request
    expect(moved.y, greaterThan(50 + 50));
    // Roughly the same 2:1 aspect ratio as the requested (200,100) move.
    expect((moved.x - 50) / (moved.y - 50), closeTo(2.0, 0.5));
  });

  testWidgets('connecting an output socket to an input socket adds an edge',
      (tester) async {
    final graph = FlowGraph(
      id: 'g1',
      nodes: const [
        GraphNode(
          id: 'source',
          kind: 'literal',
          position: GraphPoint(0, 0),
          inputs: [],
          outputs: [Socket(id: 'out', label: 'Value', type: SocketType.number)],
        ),
        GraphNode(
          id: 'sink',
          kind: 'output',
          position: GraphPoint(300, 0),
          inputs: [Socket(id: 'in', label: 'In', type: SocketType.number)],
          outputs: [],
        ),
      ],
      edges: const [],
    );
    await tester.pumpWidget(_Harness(initial: graph));
    await tester.pumpAndSettle();
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.graph.edges, isEmpty);

    // Tap the exact socket dots by key rather than guessing pixel offsets
    // into the card — the two-tap connect gesture onSocketTap implements.
    await tester.tap(find.byKey(const ValueKey('socket_source_out_out')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('socket_sink_in_in')));
    await tester.pumpAndSettle();

    expect(state.graph.edges, hasLength(1));
    expect(state.graph.edges.single.sourceNode, 'source');
    expect(state.graph.edges.single.targetNode, 'sink');
  });

  testWidgets('tapping near an edge midpoint deletes it', (tester) async {
    final graph = FlowGraph(
      id: 'g1',
      nodes: const [
        GraphNode(
          id: 'a',
          kind: 'literal',
          position: GraphPoint(0, 0),
          inputs: [],
          outputs: [Socket(id: 'out', label: 'Value', type: SocketType.number)],
        ),
        GraphNode(
          id: 'b',
          kind: 'output',
          position: GraphPoint(300, 0),
          inputs: [Socket(id: 'in', label: 'In', type: SocketType.number)],
          outputs: [],
        ),
      ],
      edges: const [
        GraphEdge(
            sourceNode: 'a',
            sourceSocket: 'out',
            targetNode: 'b',
            targetSocket: 'in'),
      ],
    );
    await tester.pumpWidget(_Harness(initial: graph));
    await tester.pumpAndSettle();
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.graph.edges, hasLength(1));

    // Edge midpoint per _GraphPainter/_onTapDown: start = a.position +
    // (180,20), end = b.position + (0,20); mid is their average, in the
    // NodeEditor's own coordinate space (pan=0, zoom=1 initially).
    final editorTopLeft = tester.getTopLeft(find.byType(NodeEditor));
    final start = editorTopLeft + const Offset(180, 20);
    final end = editorTopLeft + const Offset(300, 20);
    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

    await tester.tapAt(mid);
    await tester.pumpAndSettle();

    expect(state.graph.edges, isEmpty);
  });

  testWidgets('tapping a node calls onNodeSelected with its id',
      (tester) async {
    final graph = FlowGraph(
      id: 'g1',
      nodes: const [
        GraphNode(
          id: 'n1',
          kind: 'literal',
          position: GraphPoint(50, 50),
          inputs: [],
          outputs: [Socket(id: 'out', label: 'Value', type: SocketType.number)],
        ),
      ],
      edges: const [],
    );
    String? selected;
    await tester.pumpWidget(
      _Harness(initial: graph, onNodeSelected: (id) => selected = id),
    );
    await tester.pumpAndSettle();

    await tester.tap(_onCanvas('Constant'));
    await tester.pumpAndSettle();

    expect(selected, 'n1');
  });
}
