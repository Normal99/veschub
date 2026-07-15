/// Converts between [CanvasNode] (editor scene graph) and [WidgetInstance]
/// (dashboard document).
///
/// The editor operates on [CanvasNode]s with a [Matrix4] transform; the
/// document stores [WidgetInstance]s with a 6-element affine transform array.
/// This module bridges the two so save/load round-trips.
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/widgets.dart';

/// Creates a [CanvasNode] from a [WidgetInstance], decomposing the document's
/// 6-element transform into a [Matrix4].
CanvasNode nodeFromWidget(WidgetInstance w) {
  final t = w.transform;
  final matrix = Matrix4(
    t[0], t[1], 0, 0, // column 0
    t[2], t[3], 0, 0, // column 1
    0, 0, 1, 0, // column 2
    t[4], t[5], 0, 1, // column 3 (translation)
  );
  return CanvasNode(
    id: w.id,
    transform: matrix,
    z: w.z,
    data: w,
  );
}

/// Creates a [WidgetInstance] from a [CanvasNode], extracting the 6-element
/// affine transform from the [Matrix4].
WidgetInstance widgetFromNode(CanvasNode node) {
  final existing = node.data as WidgetInstance?;
  final m = node.transform.storage;
  // Row-major affine: [scaleX, skewY, skewX, scaleY, translateX, translateY]
  final transform = [m[0], m[1], m[4], m[5], m[12], m[13]];
  if (existing == null) {
    return WidgetInstance(
      id: node.id,
      kind: 'text',
      transform: transform,
      z: node.z,
    );
  }
  return existing.copyWith(transform: transform, z: node.z);
}

/// Default node dimensions (used by the canvas for hit-testing/layout).
const double kDefaultNodeWidth = 300;
const double kDefaultNodeHeight = 220;

/// Default canvas size for a new dashboard.
const CanvasSize kDefaultCanvasSize = CanvasSize(width: 1280, height: 720);

/// Default background colour (ARGB int) for a new dashboard.
const int kDefaultBackground = 0xFF000000;

/// Default accent colour (ARGB int) for a new dashboard.
const int kDefaultAccent = 0xFFFFFFFF;

/// Builds a [DashboardDocument] from the current scene, preserving the
/// document-level metadata (canvas size, colours, graphs) that lives outside
/// the scene graph. Pass the existing document's values (or the defaults) so
/// saving an already-authored board does not overwrite its theme.
DashboardDocument documentFromScene({
  required SceneModel scene,
  required String name,
  String description = '',
  CanvasSize canvasSize = kDefaultCanvasSize,
  int background = kDefaultBackground,
  int accent = kDefaultAccent,
  Map<String, dynamic> graphs = const {},
}) {
  return DashboardDocument(
    name: name,
    description: description,
    canvas: canvasSize,
    background: background,
    accent: accent,
    graphs: graphs,
    widgets: scene.nodes.map(widgetFromNode).toList(),
  );
}

/// Loads a [DashboardDocument] into a [SceneModel]. Returns the document-level
/// metadata so callers can seed their providers (canvas size, colours, graphs).
/// Returns `(canvasSize, background, accent, graphs)`.
(CanvasSize, int, int, Map<String, dynamic>) sceneFromDocument(
  SceneModel scene,
  DashboardDocument doc,
) {
  scene.replaceAll(doc.widgets.map(nodeFromWidget));
  return (
    doc.canvas,
    doc.background,
    doc.accent,
    Map<String, dynamic>.from(doc.graphs)
  );
}
