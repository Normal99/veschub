/// The interactive editor canvas widget.
///
/// Renders the [SceneModel] with each node transformed, layers interactive
/// handles (move/scale/rotate) over the current selection, supports
/// rubber-band selection, and routes pointer gestures through the command
/// stack + snapping. Designed to be embedded inside the studio; the node
/// payload rendering is delegated to [nodeBuilder].
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'command_stack.dart';
import 'hit_test.dart';
import 'scene_model.dart';
import 'selection_model.dart';
import 'snapping.dart';

/// Builds a widget for a node's payload (called per-frame during paint).
typedef NodeBuilder = Widget Function(CanvasNode node);

/// Distance (in canvas units) from a shape's own top edge to its rotate
/// handle, shared by the hit-test and the overlay painter so they always
/// agree on where the handle actually is.
const double _kRotateHandleDistance = 24.0;

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

  /// Whether a node is locked (e.g. via a layer panel padlock). A locked
  /// node is skipped during hit-testing entirely — it can't be selected,
  /// moved, or resized by clicking on the canvas, and pointer events pass
  /// through to whatever is underneath it. It can still be selected another
  /// way (e.g. clicking its row in a layer list) since that doesn't go
  /// through canvas hit-testing at all.
  final bool Function(CanvasNode node)? isNodeLocked;

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
    this.isNodeLocked,
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

  // Live drag transforms — bypasses scene.upsert for smooth 60 fps.
  final Map<String, Matrix4> _dragTransforms = {};

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
        final dragIds = _dragTransforms.keys.toSet();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Nodes (back to front) — use live drag transforms when dragging.
              for (final node in widget.scene.nodes) ...[
                if (dragIds.contains(node.id))
                  // Dragged node: just the Transform with no scene sync.
                  Transform(
                    key: ValueKey(node.id),
                    transform: _dragTransforms[node.id]!,
                    child: RepaintBoundary(
                      key: ValueKey('${node.id}_inner'),
                      child: SizedBox(
                        width: widget.nodeWidth(node),
                        height: widget.nodeHeight(node),
                        child: widget.nodeBuilder(node),
                      ),
                    ),
                  )
                else
                  RepaintBoundary(
                    key: ValueKey(node.id),
                    child: Transform(
                      transform: node.transform,
                      child: SizedBox(
                        width: widget.nodeWidth(node),
                        height: widget.nodeHeight(node),
                        child: widget.nodeBuilder(node),
                      ),
                    ),
                  ),
              ],
              // Selection handles + marquee overlay.
              Positioned.fill(
                child: CustomPaint(
                  painter: _OverlayPainter(
                    scene: widget.scene,
                    selection: widget.selection.ids,
                    nodeWidth: widget.nodeWidth,
                    nodeHeight: widget.nodeHeight,
                    marquee: _marqueeRect(),
                    dragTransforms: _dragTransforms,
                    guides: _drag?.guides ?? const [],
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

    // The rotate handle sits above the shape's own top edge (rotating with
    // it), i.e. outside the shape's own hit-testable bounds — so it must be
    // checked before the normal node hit-test, which would otherwise see
    // empty space there and start a marquee instead. Scoped to a single
    // selection only: a shared group-rotation pivot for multi-select is a
    // separate, still-open design decision (see ROADMAP.md).
    if (widget.selection.ids.length == 1) {
      final onlyId = widget.selection.ids.first;
      final node = widget.scene[onlyId];
      if (node != null && !(widget.isNodeLocked?.call(node) ?? false)) {
        final handlePos = _rotateHandlePosition(node);
        if ((p - handlePos).distanceSquared <=
            _cornerHitRadius * _cornerHitRadius) {
          final w = widget.nodeWidth(node);
          final h = widget.nodeHeight(node);
          final pivot =
              MatrixUtils.transformPoint(node.transform, Offset(w / 2, h / 2));
          _drag = _DragSession.rotate(
            origin: p,
            startTransforms: {onlyId: node.transform.clone()},
            pivot: pivot,
          );
          setState(() {});
          return;
        }
      }
    }

    final hit = hitTestNode(p);
    if (hit != null) {
      final shiftHeld = HardwareKeyboard.instance.isShiftPressed ||
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed;
      if (shiftHeld) {
        // Shift/Ctrl/Cmd-click toggles this node in or out of the current
        // selection, the standard way to build up a multi-selection one
        // click at a time (marquee-drag was previously the only way).
        widget.selection.toggle(hit);
        if (!widget.selection.isSelected(hit)) {
          // Just deselected via toggle — nothing to drag from here.
          setState(() {});
          return;
        }
      } else if (!widget.selection.isSelected(hit)) {
        // Plain click on a node outside the current selection replaces it,
        // matching standard selection UX (only a modifier key extends it).
        widget.selection.set(hit);
      }
      final node = widget.scene[hit];
      if (node != null) {
        final bounds = transformedBounds(
            node, widget.nodeWidth(node), widget.nodeHeight(node));
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
      if (_drag!.isRotate) {
        _applyRotate(p);
      } else if (_drag!.isResize) {
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
      // Commit transforms from drag map to scene model + command stack.
      final changes = <String, (Matrix4, Matrix4)>{};
      for (final entry in _drag!.startTransforms.entries) {
        final finalTransform = _dragTransforms[entry.key];
        if (finalTransform != null && !_matrixEq(finalTransform, entry.value)) {
          changes[entry.key] = (entry.value.clone(), finalTransform.clone());
          widget.scene.upsert(
            widget.scene[entry.key]!.copyWith(
              transform: finalTransform,
            ),
          );
        }
      }
      if (changes.isNotEmpty) {
        final cmd = TransformNodesCommand(changes);
        widget.commands.execute(cmd);
        widget.onCommandExecuted?.call(cmd);
      }
      widget.onGuidesChanged?.call(const []);
      _drag = null;
      _dragTransforms.clear();
    }
    _marqueeStart = null;
    _marqueeCurrent = null;
    setState(() {});
  }

  void _applyMove(Offset p) {
    final drag = _drag;
    if (drag == null) return;
    final delta = p - drag.origin;

    // Compute moving bounds for guide snapping.
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

    // Update drag transforms directly — NO scene.upsert, NO notifyListeners.
    for (final entry in drag.startTransforms.entries) {
      final node = widget.scene[entry.key];
      if (node != null) {
        final snapped = snap.adjustedOffset;
        final t = Matrix4.translationValues(snapped.dx, snapped.dy, 0)
          ..multiply(entry.value);
        _dragTransforms[entry.key] = _clampTransform(t, node);
      }
    }
    drag.guides = snap.guides;
    widget.onGuidesChanged?.call(snap.guides);
    setState(() {});
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
      _dragTransforms[entry.key] = _clampTransform(t, node);
    }
    setState(() {});
  }

  void _applyRotate(Offset current) {
    assert(_drag != null && _drag!.isRotate);
    final drag = _drag!;
    final pivot = drag.pivot;
    final currentAngle =
        math.atan2(current.dy - pivot.dy, current.dx - pivot.dx);
    final deltaAngle = currentAngle - drag.startAngle;
    for (final entry in drag.startTransforms.entries) {
      final node = widget.scene[entry.key];
      if (node == null) continue;
      final t = Matrix4.identity()
        ..translateByDouble(pivot.dx, pivot.dy, 0, 1)
        ..multiply(Matrix4.rotationZ(deltaAngle))
        ..translateByDouble(-pivot.dx, -pivot.dy, 0, 1)
        ..multiply(entry.value);
      _dragTransforms[entry.key] = _clampTransform(t, node);
    }
    setState(() {});
  }

  /// World-space position of the rotate handle: a fixed distance above the
  /// shape's own local top-centre, transformed by its current matrix so the
  /// handle rotates along with an already-rotated shape.
  Offset _rotateHandlePosition(CanvasNode node) {
    final w = widget.nodeWidth(node);
    return MatrixUtils.transformPoint(
        node.transform, Offset(w / 2, -_kRotateHandleDistance));
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
        widget.isNodeLocked == null
            ? widget.scene.nodes
            : widget.scene.nodes.where((n) => !widget.isNodeLocked!(n)),
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
      if ((p - corner).distanceSquared <= _cornerHitRadius * _cornerHitRadius) {
        return corner;
      }
    }
    return null;
  }

  Set<String> hitTestRectAll(Rect rect) => hitTestRect(
        widget.isNodeLocked == null
            ? widget.scene.nodes
            : widget.scene.nodes.where((n) => !widget.isNodeLocked!(n)),
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
  final bool isRotate;
  final Offset pivot;
  final double startAngle;
  List<GuideLine> guides;

  _DragSession({
    required this.origin,
    required this.startTransforms,
    this.isResize = false,
    this.resizeAnchor = Offset.zero,
    this.initialScale = 1.0,
    this.isRotate = false,
    this.pivot = Offset.zero,
    this.startAngle = 0.0,
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

  factory _DragSession.rotate({
    required Offset origin,
    required Map<String, Matrix4> startTransforms,
    required Offset pivot,
  }) =>
      _DragSession(
        origin: origin,
        startTransforms: startTransforms,
        isRotate: true,
        pivot: pivot,
        startAngle: math.atan2(origin.dy - pivot.dy, origin.dx - pivot.dx),
      );
}

class _OverlayPainter extends CustomPainter {
  final SceneModel scene;
  final Set<String> selection;
  final double Function(CanvasNode) nodeWidth;
  final double Function(CanvasNode) nodeHeight;
  final Rect? marquee;
  final Map<String, Matrix4>? dragTransforms;
  final List<GuideLine> guides;

  _OverlayPainter({
    required this.scene,
    required this.selection,
    required this.nodeWidth,
    required this.nodeHeight,
    required this.marquee,
    this.dragTransforms,
    this.guides = const [],
  });

  Matrix4 _currentTransform(CanvasNode node) {
    return dragTransforms?[node.id] ?? node.transform;
  }

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
  static final _rotateHandlePaint = Paint()..color = const Color(0xFFFFFFFF);
  static final _rotateLinePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..color = const Color(0xFF4FC3F7);

  @override
  void paint(Canvas canvas, Size size) {
    for (final id in selection) {
      final node = scene[id];
      if (node == null) continue;
      final transform = _currentTransform(node);
      final tempNode = CanvasNode(id: node.id, transform: transform);
      final bounds =
          transformedBounds(tempNode, nodeWidth(node), nodeHeight(node));
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

      // Rotate handle: single-selection only (see EditorCanvas._onPanStart
      // for why group rotation is deliberately out of scope for now).
      if (selection.length == 1) {
        final w = nodeWidth(node);
        final topCentre =
            MatrixUtils.transformPoint(transform, Offset(w / 2, 0));
        final handle = MatrixUtils.transformPoint(
            transform, Offset(w / 2, -_kRotateHandleDistance));
        canvas.drawLine(topCentre, handle, _rotateLinePaint);
        canvas.drawCircle(handle, 5, _rotateHandlePaint);
        canvas.drawCircle(handle, 5, _handleStroke);
      }
    }

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
      old.scene != scene ||
      old.selection != selection ||
      old.dragTransforms != dragTransforms;
}
