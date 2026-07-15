/// Hit-testing and coordinate-space conversions for the editor canvas.
///
/// The canvas paints nodes with their [CanvasNode.transform] applied; to test
/// whether a pointer hit a node we transform the pointer from canvas space into
/// the node's local space and check the node's local bounds.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'scene_model.dart';

/// Hit-tests [nodes] (already sorted back-to-front) and returns the topmost
/// node whose local [bounds] contains [canvasPoint], or `null`.
///
/// [bounds] is the node's unscaled local rectangle (e.g. `Rect.fromLTWH(0,0,w,h)`).
String? hitTest(
  Iterable<CanvasNode> nodes,
  Offset canvasPoint,
  double Function(CanvasNode) boundsWidth,
  double Function(CanvasNode) boundsHeight,
) {
  // Iterate front-to-back (reverse of z-sorted list).
  for (final node in nodes.toList().reversed) {
    Matrix4 local;
    try {
      local = node.transform.clone()..invert();
    } catch (_) {
      continue;
    }
    final p = MatrixUtils.transformPoint(local, canvasPoint);
    final w = boundsWidth(node);
    final h = boundsHeight(node);
    if (p.dx >= 0 && p.dx <= w && p.dy >= 0 && p.dy <= h) {
      return node.id;
    }
  }
  return null;
}

/// Returns all node ids whose transformed bounds intersect [rect] (rubber-band
/// selection). A node is selected if its transformed bounding box intersects
/// the marquee rectangle.
Set<String> hitTestRect(
  Iterable<CanvasNode> nodes,
  Rect rect,
  double Function(CanvasNode) boundsWidth,
  double Function(CanvasNode) boundsHeight,
) {
  final selected = <String>{};
  for (final node in nodes) {
    final box = transformedBounds(node, boundsWidth(node), boundsHeight(node));
    if (rect.overlaps(box)) selected.add(node.id);
  }
  return selected;
}

/// Computes the axis-aligned bounding box of a node after its transform is
/// applied to its local [width]×[height] rectangle.
Rect transformedBounds(CanvasNode node, double width, double height) {
  final corners = [
    Offset.zero,
    Offset(width, 0),
    Offset(width, height),
    Offset(0, height),
  ].map((c) => MatrixUtils.transformPoint(node.transform, c)).toList();
  final left = corners.map((c) => c.dx).reduce(math.min);
  final top = corners.map((c) => c.dy).reduce(math.min);
  final right = corners.map((c) => c.dx).reduce(math.max);
  final bottom = corners.map((c) => c.dy).reduce(math.max);
  return Rect.fromLTRB(left, top, right, bottom);
}
