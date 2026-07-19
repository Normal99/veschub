/// The interactive editor canvas widget.
///
/// Renders the [SceneModel] with each node transformed, layers interactive
/// handles (move/scale/rotate) over the current selection, supports
/// rubber-band selection, and routes pointer gestures through the command
/// stack + snapping. Designed to be embedded inside the studio; the node
/// payload rendering is delegated to [nodeBuilder].
library;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'command_stack.dart';
import 'hit_test.dart';
import 'scene_model.dart';
import 'selection_model.dart';
import 'snapping.dart';

/// Builds a widget for a node's payload (called per-frame during paint).
typedef NodeBuilder = Widget Function(CanvasNode node);

class EditorCanvas extends StatefulWidget {
  final SceneModel scene;
  final SelectionModel selection;
  final CommandStack commands;
  final NodeBuilder nodeBuilder;
  final double Function(CanvasNode) nodeWidth;
  final double Function(CanvasNode) nodeHeight;
  final SnapConfig snapConfig;
  final ValueChanged<List<GuideLine>>? onGuidesChanged;

  /// Called whenever the canvas itself executes a command (e.g. a move).
  /// Lets the host mark the document dirty.
  final ValueChanged<EditorCommand>? onCommandExecuted;

  /// The logical canvas size. When set, widgets are clamped so they cannot
  /// be moved or resized beyond the canvas boundaries.
  final Size? canvasSize;

  /// Whether to draw a grid overlay. Use with [gridSize] in [snapConfig].
  final bool showGrid;

  const EditorCanvas({
    required this.scene,
    required this.selection,
    required this.commands,
    required this.nodeBuilder,
    required this.nodeWidth,
    required this.nodeHeight,
    this.snapConfig = const SnapConfig(),
    this.onGuidesChanged,
    this.onCommandExecuted,
    this.canvasSize,
    this.showGrid = false,
    super.key,
  });

  @override
  State<EditorCanvas> createState() => _EditorCanvasState();
}

class _EditorCanvasState extends State<EditorCanvas> {
  // Marquee (rubber-band) selection state, in canvas coordinates.
  Offset? _marqueeStart;
  Offset? _marqueeCurrent;

  // Active drag state for the current gesture.
  _DragSession? _drag;

  @override
  void initState() {
    super.initState();
    widget.scene.addListener(_onSceneChanged);
    widget.selection.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant EditorCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) {
      oldWidget.scene.removeListener(_onSceneChanged);
      widget.scene.addListener(_onSceneChanged);
    }
    if (oldWidget.selection != widget.selection) {
      oldWidget.selection.removeListener(_onSelectionChanged);
      widget.selection.addListener(_onSelectionChanged);
    }
  }

  @override
  void dispose() {
    widget.scene.removeListener(_onSceneChanged);
    widget.selection.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSceneChanged() => setState(() {});
  void _onSelectionChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Nodes (back to front).
              for (final node in widget.scene.nodes)
                Transform(
                  transform: node.transform,
                  child: SizedBox(
                    width: widget.nodeWidth(node),
                    height: widget.nodeHeight(node),
                    child: widget.nodeBuilder(node),
                  ),
                ),
              // Selection handles + marquee overlay.
              Positioned.fill(
                child: CustomPaint(
                  painter: _OverlayPainter(
                    scene: widget.scene,
                    selection: widget.selection.ids,
                    nodeWidth: widget.nodeWidth,
                    nodeHeight: widget.nodeHeight,
                    marquee: _marqueeRect(),
                    guides: _drag?.guides ?? const [],
                    showGrid: widget.showGrid,
                    gridSize: widget.snapConfig.gridSize,
                    canvasSize: widget.canvasSize,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Rect? _marqueeRect() {
    if (_marqueeStart == null || _marqueeCurrent == null) return null;
    return Rect.fromPoints(_marqueeStart!, _marqueeCurrent!);
  }

  void _onPanStart(DragStartDetails details) {
    final p = details.localPosition;
    final hit = hitTestNode(p);
    if (hit != null) {
      if (!widget.selection.isSelected(hit)) {
        if (!widget.selection.isMultiple) {
          widget.selection.set(hit);
        } else {
          widget.selection.add(hit);
        }
      }
      final node = widget.scene[hit];
      if (node != null) {
        final bounds =
            transformedBounds(node, widget.nodeWidth(node), widget.nodeHeight(node));
        final corner = _hitTestCorner(p, bounds);
        if (corner != null) {
          final anchor = Offset(
            bounds.center.dx - (corner.dx - bounds.center.dx),
            bounds.center.dy - (corner.dy - bounds.center.dy),
          );
          _drag = _DragSession.resize(
            origin: p,
            startTransforms: {
              for (final id in widget.selection.ids)
                id: widget.scene[id]!.transform.clone(),
            },
            resizeAnchor: anchor,
          );
          setState(() {});
          return;
        }
      }
      _drag = _DragSession.move(
        origin: p,
        startTransforms: {
          for (final id in widget.selection.ids)
            id: widget.scene[id]!.transform.clone(),
        },
      );
    } else {
      // Clicked empty space: start marquee, clear existing selection.
      widget.selection.clear();
      _marqueeStart = p;
      _marqueeCurrent = p;
    }
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final p = details.localPosition;
    if (_drag != null) {
      if (_drag!.isResize) {
        _applyResize(p);
      } else {
        _applyMove(p);
      }
    } else if (_marqueeStart != null) {
      _marqueeCurrent = p;
      final rect = Rect.fromPoints(_marqueeStart!, p);
      final hits = hitTestRectAll(rect);
      widget.selection.setAll(hits);
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_drag != null) {
      // Commit the transform as a single undoable command.
      final changes = <String, (Matrix4, Matrix4)>{};
      for (final entry in _drag!.startTransforms.entries) {
        final current = widget.scene[entry.key]?.transform;
        if (current != null && !_matrixEq(current, entry.value)) {
          changes[entry.key] = (entry.value.clone(), current.clone());
        }
      }
      if (changes.isNotEmpty) {
        final cmd = TransformNodesCommand(changes);
        widget.commands.execute(cmd);
        widget.onCommandExecuted?.call(cmd);
      }
      widget.onGuidesChanged?.call(const []);
      _drag = null;
    }
    _marqueeStart = null;
    _marqueeCurrent = null;
    setState(() {});
  }

  void _applyMove(Offset p) {
    final drag = _drag;
    if (drag == null) return;
    final delta = p - drag.origin;

    // Compute moving bounds (union) for guide snapping.
    final movingBounds = <Rect>[];
    for (final id in drag.startTransforms.keys) {
      final node = widget.scene[id];
      if (node != null) {
        movingBounds.add(
          transformedBounds(
            node,
            widget.nodeWidth(node),
            widget.nodeHeight(node),
          ),
        );
      }
    }
    final otherBounds = widget.scene.nodes
        .where((n) => !drag.startTransforms.containsKey(n.id))
        .map(
          (n) =>
              transformedBounds(n, widget.nodeWidth(n), widget.nodeHeight(n)),
        )
        .toList();

    final union = movingBounds.fold<Rect>(
      Rect.zero,
      (a, b) => a.isEmpty ? b : a.expandToInclude(b),
    );
    final snap = snapTranslation(
      origin: Offset.zero,
      rawDelta: delta,
      movingBounds: union.translate(-union.left, -union.top),
      otherBounds: otherBounds,
      config: widget.snapConfig,
      canvasSize: widget.canvasSize,
    );

    // Apply the snapped delta directly to the scene (live preview; committed on end).
    for (final entry in drag.startTransforms.entries) {
      final node = widget.scene[entry.key];
      if (node != null) {
        final snapped = snap.adjustedOffset;
        final t = Matrix4.translationValues(snapped.dx, snapped.dy, 0)
          ..multiply(entry.value);
        final cmat = _clampTransform(t, node);
        widget.scene.upsert(node.copyWith(transform: cmat));
      }
    }
    drag.guides = snap.guides;
    widget.onGuidesChanged?.call(snap.guides);
  }

  void _applyResize(Offset current) {
    assert(_drag != null && _drag!.isResize);
    final drag = _drag!;
    final newDist = (current - drag.resizeAnchor).distance;
    final scale = drag.initialScale > 0 ? newDist / drag.initialScale : 1.0;
    final clamped = scale.clamp(0.2, 5.0);
    final anchor = drag.resizeAnchor;
    for (final entry in drag.startTransforms.entries) {
      final node = widget.scene[entry.key];
      if (node == null) continue;
      final t = Matrix4.identity()
        ..translateByDouble(anchor.dx, anchor.dy, 0, 1)
        ..scaleByDouble(clamped, clamped, 1.0, 1)
        ..translateByDouble(-anchor.dx, -anchor.dy, 0, 1)
        ..multiply(entry.value);
      final cmat = _clampTransform(t, node);
      widget.scene.upsert(node.copyWith(transform: cmat));
    }
  }

  Matrix4 _clampTransform(Matrix4 transform, CanvasNode node) {
    final cs = widget.canvasSize;
    if (cs == null) return transform;
    final w = widget.nodeWidth(node);
    final h = widget.nodeHeight(node);
    final temp = CanvasNode(id: '', transform: transform);
    final b = transformedBounds(temp, w, h);
    var dx = 0.0;
    var dy = 0.0;
    if (b.left < 0 && b.right > cs.width) {
      dx = -b.left;
    } else if (b.left < 0) {
      dx = -b.left;
    } else if (b.right > cs.width) {
      dx = cs.width - b.right;
    }
    if (b.top < 0 && b.bottom > cs.height) {
      dy = -b.top;
    } else if (b.top < 0) {
      dy = -b.top;
    } else if (b.bottom > cs.height) {
      dy = cs.height - b.bottom;
    }
    if (dx == 0 && dy == 0) return transform;
    return Matrix4.translationValues(dx, dy, 0)..multiply(transform);
  }

  String? hitTestNode(Offset p) => hitTest(
        widget.scene.nodes,
        p,
        widget.nodeWidth,
        widget.nodeHeight,
      );

  static const _cornerHitRadius = 14.0;

  Offset? _hitTestCorner(Offset p, Rect bounds) {
    for (final corner in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      if ((p - corner).distanceSquared <=
          _cornerHitRadius * _cornerHitRadius) {
        return corner;
      }
    }
    return null;
  }

  Set<String> hitTestRectAll(Rect rect) => hitTestRect(
        widget.scene.nodes,
        rect,
        widget.nodeWidth,
        widget.nodeHeight,
      );

  bool _matrixEq(Matrix4 a, Matrix4 b) {
    final sa = a.storage, sb = b.storage;
    for (var i = 0; i < 16; i++) {
      if ((sa[i] - sb[i]).abs() > 1e-9) return false;
    }
    return true;
  }
}

class _DragSession {
  final Offset origin;
  final Map<String, Matrix4> startTransforms;
  final bool isResize;
  final Offset resizeAnchor;
  final double initialScale;
  List<GuideLine> guides;

  _DragSession({
    required this.origin,
    required this.startTransforms,
    this.isResize = false,
    this.resizeAnchor = Offset.zero,
    this.initialScale = 1.0,
  }) : guides = const [];

  factory _DragSession.move({
    required Offset origin,
    required Map<String, Matrix4> startTransforms,
  }) =>
      _DragSession(origin: origin, startTransforms: startTransforms);

  factory _DragSession.resize({
    required Offset origin,
    required Map<String, Matrix4> startTransforms,
    required Offset resizeAnchor,
  }) =>
      _DragSession(
        origin: origin,
        startTransforms: startTransforms,
        isResize: true,
        resizeAnchor: resizeAnchor,
        initialScale: (origin - resizeAnchor).distance,
      );
}

class _OverlayPainter extends CustomPainter {
  final SceneModel scene;
  final Set<String> selection;
  final double Function(CanvasNode) nodeWidth;
  final double Function(CanvasNode) nodeHeight;
  final Rect? marquee;
  final List<GuideLine> guides;
  final bool showGrid;
  final double gridSize;
  final Size? canvasSize;

  _OverlayPainter({
    required this.scene,
    required this.selection,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.marquee,
    required this.guides,
    required this.showGrid,
    required this.gridSize,
    required this.canvasSize,
  });

  static final _selectPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..color = const Color(0xFF4FC3F7);
  static final _handlePaint = Paint()..color = const Color(0xFFFFFFFF);
  static final _handleStroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFF1565C0);
  static final _marqueePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0x884FC3F7);
  static final _marqueeFill = Paint()..color = const Color(0x224FC3F7);
  static final _guidePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFFFF4081);
  static final _gridPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5
    ..color = const Color(0x20FFFFFF);
  static final _centerPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = const Color(0x30FFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    // Selection outlines + handles.
    for (final id in selection) {
      final node = scene[id];
      if (node == null) continue;
      final bounds = transformedBounds(node, nodeWidth(node), nodeHeight(node));
      canvas.drawRect(bounds.inflate(2), _selectPaint);
      for (final corner in [
        bounds.topLeft,
        bounds.topRight,
        bounds.bottomLeft,
        bounds.bottomRight,
      ]) {
        canvas.drawCircle(corner, 5, _handlePaint);
        canvas.drawCircle(corner, 5, _handleStroke);
      }
    }

    // Marquee.
    if (marquee != null) {
      canvas.drawRect(marquee!, _marqueeFill);
      canvas.drawRect(marquee!, _marqueePaint);
    }

    // Alignment guides.
    for (final g in guides) {
      if (g.horizontal) {
        canvas.drawLine(
          Offset(0, g.position),
          Offset(size.width, g.position),
          _guidePaint,
        );
      } else {
        canvas.drawLine(
          Offset(g.position, 0),
          Offset(g.position, size.height),
          _guidePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) =>
      old.marquee != marquee ||
      old.guides != guides ||
      old.showGrid != showGrid ||
      old.gridSize != gridSize ||
      old.scene != scene ||
      old.selection != selection;

  void _drawGrid(Canvas canvas, Size size) {
    if (!showGrid || gridSize <= 0) return;
    final w = canvasSize?.width ?? size.width;
    final h = canvasSize?.height ?? size.height;
    for (var x = 0.0; x <= w; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), _gridPaint);
    }
    for (var y = 0.0; y <= h; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(w, y), _gridPaint);
    }
    if (canvasSize != null) {
      canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), _centerPaint);
      canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), _centerPaint);
    }
  }
}
