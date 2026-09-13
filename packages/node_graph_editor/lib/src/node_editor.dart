/// Interactive dataflow graph editor widget.
///
/// Renders a [FlowGraph] as a pannable canvas with draggable nodes and
/// connectable sockets. The studio's Flow mode embeds this widget. Node
/// positions use [GraphPoint] (pure Dart) internally; the editor converts
/// to/from [Offset] for rendering.
library;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:node_graph/node_graph.dart';

/// Callback when the graph is modified (nodes moved, edges added/removed).
typedef GraphChanged = void Function(FlowGraph graph);

/// An interactive node-graph editor.
class NodeEditor extends StatefulWidget {
  final FlowGraph graph;
  final GraphChanged onChanged;
  final Map<String, Map<String, dynamic>> properties;
  final ValueChanged<String>? onNodeSelected;
  final String? selectedNodeId;

  const NodeEditor({
    required this.graph,
    required this.onChanged,
    this.properties = const {},
    this.onNodeSelected,
    this.selectedNodeId,
    super.key,
  });

  @override
  State<NodeEditor> createState() => _NodeEditorState();
}

class _NodeEditorState extends State<NodeEditor> {
  Offset _pan = Offset.zero;
  double _zoom = 1.0;

  // Pending connection drag: source node + socket.
  String? _dragSourceNode;
  String? _dragSourceSocket;
  Offset? _dragCurrent;

  // Node drag state.
  String? _draggingNode;

  GraphPoint _toGraph(Offset screen) =>
      GraphPoint((screen.dx - _pan.dx) / _zoom, (screen.dy - _pan.dy) / _zoom);

  Offset _toScreen(GraphPoint p) =>
      Offset(p.x * _zoom + _pan.dx, p.y * _zoom + _pan.dy);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: _onPointerSignal,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: _onPan,
        onTapDown: _onTapDown,
        child: ClipRect(
          child: DragTarget<String>(
            onAcceptWithDetails: (details) {
              final kind = details.data;
              final def = builtInNodeKinds[kind];
              if (def == null) return;
              final pos = _toGraph(details.offset);
              final id = '${kind}_${DateTime.now().millisecondsSinceEpoch}';
              final node = GraphNode(
                id: id,
                kind: kind,
                position: pos,
                inputs: def.inputs,
                outputs: def.outputs,
              );
              widget.onChanged(
                widget.graph.copyWith(nodes: [...widget.graph.nodes, node]),
              );
            },
            builder: (context, candidate, rejected) {
              return CustomPaint(
                painter: _GraphPainter(
                  graph: widget.graph,
                  toScreen: _toScreen,
                  selectedNodeId: widget.selectedNodeId,
                  dragFrom: _dragSourceNode != null && _dragCurrent != null
                      ? _toScreen(
                          widget.graph.node(_dragSourceNode!)!.position,
                        )
                      : null,
                  dragTo: _dragCurrent,
                  showDropHint: candidate.isNotEmpty,
                ),
                child: Stack(
                  children: [
                    for (final node in widget.graph.nodes)
                      _NodeCard(
                        node: node,
                        position: _toScreen(node.position),
                        isSelected: node.id == widget.selectedNodeId,
                        onTap: () {
                          widget.onNodeSelected?.call(node.id);
                        },
                        onPanStart: (details) {
                          if (_dragSourceNode != null) return;
                          _draggingNode = node.id;
                        },
                        onPanUpdate: (details) {
                          if (_draggingNode != node.id) return;
                          // Move by the incremental delta (zoom-adjusted)
                          // rather than recomputing an absolute position
                          // from a mix of local pan-start and global
                          // pan-update coordinates — that mix silently
                          // added the editor's own screen offset (e.g. a
                          // palette sidebar to its left) into every drag,
                          // making nodes jump when dragged in the real app
                          // layout (caught by node_editor_test.dart using
                          // a harness with a sidebar, not by testing the
                          // editor alone at the screen origin).
                          final newPos = GraphPoint(
                            node.position.x + details.delta.dx / _zoom,
                            node.position.y + details.delta.dy / _zoom,
                          );
                          final updated = node.copyWith(position: newPos);
                          final newNodes = widget.graph.nodes
                              .map((n) => n.id == node.id ? updated : n)
                              .toList();
                          widget.onChanged(
                            widget.graph.copyWith(nodes: newNodes),
                          );
                        },
                        onPanEnd: (_) => _draggingNode = null,
                        onSocketTap: (socketId, isOutput, screenPos) {
                          if (isOutput) {
                            setState(() {
                              _dragSourceNode = node.id;
                              _dragSourceSocket = socketId;
                              _dragCurrent = screenPos;
                            });
                          } else if (_dragSourceNode != null) {
                            // Complete connection.
                            final edge = GraphEdge(
                              sourceNode: _dragSourceNode!,
                              sourceSocket: _dragSourceSocket!,
                              targetNode: node.id,
                              targetSocket: socketId,
                            );
                            if (!widget.graph.edges.contains(edge)) {
                              widget.onChanged(
                                widget.graph.copyWith(
                                  edges: [...widget.graph.edges, edge],
                                ),
                              );
                            }
                            setState(() {
                              _dragSourceNode = null;
                              _dragSourceSocket = null;
                              _dragCurrent = null;
                            });
                          }
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onPan(DragUpdateDetails details) {
    if (_dragSourceNode != null) {
      setState(() => _dragCurrent = _dragCurrent! + details.delta);
    } else if (_draggingNode == null) {
      setState(() => _pan += details.delta);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      setState(() {
        _zoom = (_zoom - event.scrollDelta.dy * 0.001).clamp(0.3, 3.0);
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    final local = details.localPosition;
    // Hit-test edges: if the tap is near an edge's midpoint, delete it.
    for (final edge in widget.graph.edges) {
      final source = widget.graph.node(edge.sourceNode);
      final target = widget.graph.node(edge.targetNode);
      if (source == null || target == null) continue;
      final start = _toScreen(source.position) + const Offset(180, 20);
      final end = _toScreen(target.position) + const Offset(0, 20);
      final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
      if ((local - mid).distance < 20) {
        final newEdges = widget.graph.edges
            .where(
              (e) => !(e.sourceNode == edge.sourceNode &&
                  e.sourceSocket == edge.sourceSocket &&
                  e.targetNode == edge.targetNode &&
                  e.targetSocket == edge.targetSocket),
            )
            .toList();
        widget.onChanged(
          widget.graph.copyWith(edges: newEdges),
        );
        return;
      }
    }
  }
}

class _NodeCard extends StatelessWidget {
  final GraphNode node;
  final Offset position;
  final bool isSelected;
  final VoidCallback onTap;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;
  final void Function(String socketId, bool isOutput, Offset screenPos)
      onSocketTap;

  const _NodeCard({
    required this.node,
    required this.position,
    required this.isSelected,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onSocketTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        onPanStart: onPanStart,
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade600,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_iconFor(node.kind), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _labelFor(node.kind),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Sockets
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final socket in node.inputs)
                      _SocketRow(
                        dotKey: ValueKey('socket_${node.id}_${socket.id}_in'),
                        socket: socket,
                        isOutput: false,
                        onTap: (pos) => onSocketTap(socket.id, false, pos),
                      ),
                    for (final socket in node.outputs)
                      _SocketRow(
                        dotKey: ValueKey('socket_${node.id}_${socket.id}_out'),
                        socket: socket,
                        isOutput: true,
                        onTap: (pos) => onSocketTap(socket.id, true, pos),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

  String _labelFor(String kind) => builtInNodeKinds[kind]?.displayName ?? kind;
}

class _SocketRow extends StatelessWidget {
  final Key dotKey;
  final Socket socket;
  final bool isOutput;
  final void Function(Offset pos) onTap;

  const _SocketRow({
    required this.dotKey,
    required this.socket,
    required this.isOutput,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isOutput ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isOutput) _SocketDot(key: dotKey, socket: socket, onTap: onTap),
        if (!isOutput)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(socket.label, style: const TextStyle(fontSize: 11)),
          ),
        if (isOutput)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(socket.label, style: const TextStyle(fontSize: 11)),
          ),
        if (isOutput) _SocketDot(key: dotKey, socket: socket, onTap: onTap),
      ],
    );
  }
}

class _SocketDot extends StatelessWidget {
  final Socket socket;
  final void Function(Offset pos) onTap;

  const _SocketDot({super.key, required this.socket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => onTap(details.globalPosition),
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: _colorFor(socket.type),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black54, width: 1),
        ),
      ),
    );
  }

  Color _colorFor(SocketType t) => switch (t) {
        SocketType.number => Colors.blue,
        SocketType.boolean => Colors.orange,
        SocketType.string => Colors.green,
        SocketType.any => Colors.purple,
      };
}

class _GraphPainter extends CustomPainter {
  final FlowGraph graph;
  final Offset Function(GraphPoint) toScreen;
  final String? selectedNodeId;
  final Offset? dragFrom;
  final Offset? dragTo;
  final bool showDropHint;

  _GraphPainter({
    required this.graph,
    required this.toScreen,
    this.selectedNodeId,
    this.dragFrom,
    this.dragTo,
    this.showDropHint = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.blue;

    // Draw edges as bezier curves.
    for (final edge in graph.edges) {
      final source = graph.node(edge.sourceNode);
      final target = graph.node(edge.targetNode);
      if (source == null || target == null) continue;
      final start = toScreen(source.position) + const Offset(180, 20);
      final end = toScreen(target.position) + const Offset(0, 20);
      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..cubicTo(midX, start.dy, midX, end.dy, end.dx, end.dy);
      canvas.drawPath(path, paint);
    }

    // Draw pending connection.
    if (dragFrom != null && dragTo != null) {
      final midX = (dragFrom!.dx + dragTo!.dx) / 2;
      final path = Path()
        ..moveTo(dragFrom!.dx, dragFrom!.dy)
        ..cubicTo(midX, dragFrom!.dy, midX, dragTo!.dy, dragTo!.dx, dragTo!.dy);
      canvas.drawPath(
        path,
        paint..color = Colors.blue.withValues(alpha: 0.5),
      );
    }

    // Draw a drop hint overlay when a palette item is being dragged over the
    // canvas.
    if (showDropHint) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.blue.withValues(alpha: 0.06),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) =>
      old.graph != graph ||
      old.dragTo != dragTo ||
      old.showDropHint != showDropHint ||
      old.toScreen != toScreen;
}
