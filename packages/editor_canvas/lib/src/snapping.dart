/// Snapping helpers — grid snap and Figma-style alignment guides.
library;

import 'package:flutter/widgets.dart';

/// Configuration for snapping behaviour.
class SnapConfig {
  /// Grid spacing in canvas units; 0 disables grid snap.
  final double gridSize;

  /// Snap distance threshold in canvas units (how close before it snaps).
  final double threshold;

  /// Enable alignment-guide snapping to other nodes' edges/centres.
  final bool enableGuides;

  /// Enable snapping to the canvas centre lines (vertical + horizontal).
  final bool enableCenterSnap;

  const SnapConfig({
    this.gridSize = 8.0,
    this.threshold = 8.0,
    this.enableGuides = true,
    this.enableCenterSnap = true,
  });

  static const disabled =
      SnapConfig(gridSize: 0, threshold: 0, enableGuides: false, enableCenterSnap: false);
}

/// The result of a snap operation: the adjusted delta and any guides drawn.
class SnapResult {
  final Offset adjustedOffset;
  final List<GuideLine> guides;

  const SnapResult(this.adjustedOffset, this.guides);
}

/// A visual alignment guide (horizontal or vertical) drawn during snap.
class GuideLine {
  final bool horizontal;
  final double position;

  const GuideLine.vertical(this.position) : horizontal = false;
  const GuideLine.horizontal(this.position) : horizontal = true;
}

/// Snaps [rawDelta] (a proposed translation delta) for the moving node(s).
///
/// Grid snapping snaps the moved widget's **edges** (left, center-x, right /
/// top, center-y, bottom) to the nearest grid line — not just the origin.
/// This makes snapping feel magnetic: any edge that comes within
/// [SnapConfig.threshold] of a grid line pulls the widget into alignment.
///
/// Guide snapping (when enabled) aligns widget edges/centres with other nodes.
SnapResult snapTranslation({
  required Offset origin,
  required Offset rawDelta,
  required Rect movingBounds,
  required Iterable<Rect> otherBounds,
  required SnapConfig config,
  Size? canvasSize,
}) {
  var delta = rawDelta;

  if (config.gridSize > 0) {
    delta = _snapToGrid(delta, movingBounds, config, canvasSize);
  }

  // Centre-line snapping (canvas vertical / horizontal centre lines).
  final guides = <GuideLine>[];
  if (config.enableCenterSnap && canvasSize != null) {
    delta = _snapToCenter(delta, movingBounds, config, canvasSize, guides);
  }

  if (!config.enableGuides || config.threshold <= 0) {
    return SnapResult(delta, guides);
  }

  // Alignment-guide snapping to other nodes.
  final moved = movingBounds.shift(delta);

  // Candidate x lines: moving left/centre/right vs other left/centre/right.
  final movingXs = [moved.left, moved.center.dx, moved.right];
  double? bestXDiff;
  double? bestXPos;
  for (final other in otherBounds) {
    final otherXs = [other.left, other.center.dx, other.right];
    for (var i = 0; i < movingXs.length; i++) {
      for (var j = 0; j < otherXs.length; j++) {
        final diff = otherXs[j] - movingXs[i];
        if (diff.abs() <= config.threshold &&
            (bestXDiff == null || diff.abs() < bestXDiff.abs())) {
          bestXDiff = diff;
          bestXPos = otherXs[j];
        }
      }
    }
  }
  if (bestXDiff != null) {
    delta = Offset(delta.dx + bestXDiff, delta.dy);
    guides.add(GuideLine.vertical(bestXPos!));
  }

  // Recompute moved after x snap.
  final movedY = movingBounds.shift(delta);
  final movingYs = [movedY.top, movedY.center.dy, movedY.bottom];
  double? bestYDiff;
  double? bestYPos;
  for (final other in otherBounds) {
    final otherYs = [other.top, other.center.dy, other.bottom];
    for (var i = 0; i < movingYs.length; i++) {
      for (var j = 0; j < otherYs.length; j++) {
        final diff = otherYs[j] - movingYs[i];
        if (diff.abs() <= config.threshold &&
            (bestYDiff == null || diff.abs() < bestYDiff.abs())) {
          bestYDiff = diff;
          bestYPos = otherYs[j];
        }
      }
    }
  }
  if (bestYDiff != null) {
    delta = Offset(delta.dx, delta.dy + bestYDiff);
    guides.add(GuideLine.horizontal(bestYPos!));
  }

  return SnapResult(delta, guides);
}

/// Snaps widget edges (left, center-x, right / top, center-y, bottom) to the
/// nearest grid line. Returns the adjusted delta.
Offset _snapToGrid(Offset delta, Rect bounds, SnapConfig config, Size? canvasSize) {
  final size = config.gridSize;
  final threshold = config.threshold;

  final snapX = <double>{};
  final snapY = <double>{};

  if (canvasSize != null) {
    for (var x = 0.0; x <= canvasSize.width; x += size) {
      snapX.add(x);
    }
    for (var y = 0.0; y <= canvasSize.height; y += size) {
      snapY.add(y);
    }
    snapX.addAll([0, canvasSize.width, canvasSize.width / 2]);
    snapY.addAll([0, canvasSize.height, canvasSize.height / 2]);
  }

  // Snap X: check left, center, right edges against all snap targets.
  final left = bounds.left + delta.dx;
  final cx = bounds.center.dx + delta.dx;
  final right = bounds.right + delta.dx;
  final edgesX = [left, cx, right];
  double? bestAdjustX;
  double? bestDistX;

  if (snapX.isEmpty) {
    for (final edge in edgesX) {
      final snapped = (edge / size).round() * size;
      final dist = (edge - snapped).abs();
      if (dist <= threshold && (bestDistX == null || dist < bestDistX)) {
        bestDistX = dist;
        bestAdjustX = snapped - edge;
      }
    }
  } else {
    for (final edge in edgesX) {
      for (final sx in snapX) {
        final dist = (edge - sx).abs();
        if (dist <= threshold && (bestDistX == null || dist < bestDistX)) {
          bestDistX = dist;
          bestAdjustX = sx - edge;
        }
      }
    }
  }

  // Snap Y: check top, center, bottom edges.
  final top = bounds.top + delta.dy;
  final cy = bounds.center.dy + delta.dy;
  final bottom = bounds.bottom + delta.dy;
  final edgesY = [top, cy, bottom];
  double? bestAdjustY;
  double? bestDistY;

  if (snapY.isEmpty) {
    for (final edge in edgesY) {
      final snapped = (edge / size).round() * size;
      final dist = (edge - snapped).abs();
      if (dist <= threshold && (bestDistY == null || dist < bestDistY)) {
        bestDistY = dist;
        bestAdjustY = snapped - edge;
      }
    }
  } else {
    for (final edge in edgesY) {
      for (final sy in snapY) {
        final dist = (edge - sy).abs();
        if (dist <= threshold && (bestDistY == null || dist < bestDistY)) {
          bestDistY = dist;
          bestAdjustY = sy - edge;
        }
      }
    }
  }

  return Offset(
    bestAdjustX != null ? delta.dx + bestAdjustX : delta.dx,
    bestAdjustY != null ? delta.dy + bestAdjustY : delta.dy,
  );
}

/// Snaps widget edges (left, center, right / top, center, bottom) to the
/// canvas centre lines (vertical at canvasWidth/2, horizontal at
/// canvasHeight/2). Returns the adjusted delta and appends guides to [out].
Offset _snapToCenter(
  Offset delta,
  Rect bounds,
  SnapConfig config,
  Size canvasSize,
  List<GuideLine> out,
) {
  final threshold = config.threshold;
  final centerX = canvasSize.width / 2;
  final centerY = canvasSize.height / 2;

  // Snap X: check left, center, right edges against vertical centre line.
  final left = bounds.left + delta.dx;
  final cx = bounds.center.dx + delta.dx;
  final right = bounds.right + delta.dx;
  final edgesX = [left, cx, right];
  double? bestDistX;
  for (final edge in edgesX) {
    final dist = (edge - centerX).abs();
    if (dist <= threshold && (bestDistX == null || dist < bestDistX)) {
      bestDistX = dist;
    }
  }
  if (bestDistX != null) {
    // Snap whichever edge is closest to the centre line.
    final leftDist = (left - centerX).abs();
    final rightDist = (right - centerX).abs();
    final cxDist = (cx - centerX).abs();
    var bestAdjustX = centerX - cx;
    if (leftDist <= threshold && (bestAdjustX == centerX - cx || leftDist < cxDist)) {
      bestAdjustX = centerX - left;
    } else if (rightDist <= threshold && (bestAdjustX == centerX - cx || rightDist < cxDist)) {
      bestAdjustX = centerX - right;
    }
    delta = Offset(delta.dx + bestAdjustX, delta.dy);
    out.add(GuideLine.vertical(centerX));
  }

  // Snap Y: check top, center, bottom edges against horizontal centre line.
  final top = bounds.top + delta.dy;
  final cy = bounds.center.dy + delta.dy;
  final bottom = bounds.bottom + delta.dy;
  final edgesY = [top, cy, bottom];
  double? bestDistY;
  for (final edge in edgesY) {
    final dist = (edge - centerY).abs();
    if (dist <= threshold && (bestDistY == null || dist < bestDistY)) {
      bestDistY = dist;
    }
  }
  if (bestDistY != null) {
    final topDist = (top - centerY).abs();
    final bottomDist = (bottom - centerY).abs();
    final cyDist = (cy - centerY).abs();
    var bestAdjustY = centerY - cy;
    if (topDist <= threshold && (bestAdjustY == centerY - cy || topDist < cyDist)) {
      bestAdjustY = centerY - top;
    } else if (bottomDist <= threshold && (bestAdjustY == centerY - cy || bottomDist < cyDist)) {
      bestAdjustY = centerY - bottom;
    }
    delta = Offset(delta.dx, delta.dy + bestAdjustY);
    out.add(GuideLine.horizontal(centerY));
  }

  return delta;
}