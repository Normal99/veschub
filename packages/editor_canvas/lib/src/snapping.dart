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

  const SnapConfig({
    this.gridSize = 8.0,
    this.threshold = 4.0,
    this.enableGuides = true,
  });

  static const disabled =
      SnapConfig(gridSize: 0, threshold: 0, enableGuides: false);
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
/// Grid snapping rounds each axis to the nearest grid multiple. Guide snapping
/// (when enabled) checks the moved node's edges/centre against every other
/// node's edges/centre and snaps within [SnapConfig.threshold].
SnapResult snapTranslation({
  required Offset origin,
  required Offset rawDelta,
  required Rect movingBounds,
  required Iterable<Rect> otherBounds,
  required SnapConfig config,
}) {
  var delta = rawDelta;

  // 1. Grid snap.
  if (config.gridSize > 0) {
    final target = origin + rawDelta;
    final sx = (target.dx / config.gridSize).round() * config.gridSize;
    final sy = (target.dy / config.gridSize).round() * config.gridSize;
    if ((target.dx - sx).abs() <= config.threshold) {
      delta = Offset(sx - origin.dx, delta.dy);
    }
    if ((target.dy - sy).abs() <= config.threshold) {
      delta = Offset(delta.dx, sy - origin.dy);
    }
  }

  if (!config.enableGuides || config.threshold <= 0) {
    return SnapResult(delta, const []);
  }

  final guides = <GuideLine>[];
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
