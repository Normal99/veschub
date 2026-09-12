/// The scene-graph node model for the editor canvas.
///
/// A [CanvasNode] is a single selectable, transformable item on the canvas.
/// Each node carries a 2D affine [Matrix4] transform (translation, rotation,
/// scale) and an arbitrary [data] payload (e.g. a `WidgetInstance` from
/// `dashboard_model`). The editor manipulates nodes via transforms; the studio
/// layer is responsible for (de)serializing nodes to/from a document.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart';

/// A single node in the editor scene graph.
@immutable
class CanvasNode {
  final String id;
  final Matrix4 transform;

  /// Z-order; higher draws on top.
  final int z;

  /// Opaque payload (e.g. a `WidgetInstance`). The editor never inspects this.
  final Object? data;

  const CanvasNode({
    required this.id,
    required this.transform,
    this.z = 0,
    this.data,
  });

  CanvasNode copyWith({
    String? id,
    Matrix4? transform,
    int? z,
    Object? data,
  }) =>
      CanvasNode(
        id: id ?? this.id,
        transform: transform ?? this.transform,
        z: z ?? this.z,
        data: data ?? this.data,
      );

  /// The translation component of [transform].
  Offset get translation =>
      Offset(transform.getTranslation()[0], transform.getTranslation()[1]);

  /// The rotation (radians) derived from the transform's basis vectors.
  double get rotation {
    final m = transform.storage;
    return math.atan2(m[1], m[0]);
  }

  /// The uniform scale derived from the transform (average of x/y basis).
  double get scale {
    final m = transform.storage;
    return (math.sqrt(m[0] * m[0] + m[1] * m[1]) +
            math.sqrt(m[4] * m[4] + m[5] * m[5])) /
        2;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasNode &&
          id == other.id &&
          _matrixEqual(transform, other.transform) &&
          z == other.z;

  @override
  int get hashCode => Object.hash(id, transform.storage, z);

  static bool _matrixEqual(Matrix4 a, Matrix4 b) {
    final sa = a.storage, sb = b.storage;
    for (var i = 0; i < 16; i++) {
      if ((sa[i] - sb[i]).abs() > 1e-9) return false;
    }
    return true;
  }
}

/// Builds common node transforms.
class NodeTransforms {
  NodeTransforms._();

  /// A translation-only transform.
  static Matrix4 translate(Offset offset) =>
      Matrix4.identity()..setTranslation(Vector3(offset.dx, offset.dy, 0));

  /// Translate + uniform scale + rotation (about the node origin).
  static Matrix4 compose({
    required Offset translation,
    double scale = 1.0,
    double rotation = 0.0,
  }) =>
      Matrix4.identity()
        ..setTranslation(Vector3(translation.dx, translation.dy, 0))
        ..multiply(Matrix4.rotationZ(rotation))
        // ignore: deprecated_member_use
        ..scale(scale, scale, 1.0);
}

/// Mutable list of [CanvasNode]s that notifies listeners on change.
///
/// The editor mutates the scene through this model; selection and the command
/// stack operate on top of it. Z-order is derived from list order (later =
/// on top) when [z] values are equal.
class SceneModel extends ChangeNotifier {
  final List<CanvasNode> _nodes = [];

  List<CanvasNode> get nodes => List.unmodifiable(_nodes);

  int get length => _nodes.length;

  CanvasNode? operator [](String id) {
    final i = _nodes.indexWhere((n) => n.id == id);
    return i >= 0 ? _nodes[i] : null;
  }

  /// Adds a node, keeping the list sorted by [CanvasNode.z] (stable).
  void add(CanvasNode node) {
    _nodes.add(node);
    _nodes.sort((a, b) => a.z.compareTo(b.z));
    notifyListeners();
  }

  /// Replaces the node with matching id, or adds it.
  void upsert(CanvasNode node) {
    final i = _nodes.indexWhere((n) => n.id == node.id);
    if (i >= 0) {
      final old = _nodes[i];
      _nodes[i] = node;
      if (old.z != node.z) {
        _nodes.sort((a, b) => a.z.compareTo(b.z));
      }
    } else {
      _nodes.add(node);
      _nodes.sort((a, b) => a.z.compareTo(b.z));
    }
    notifyListeners();
  }

  void remove(String id) {
    final before = _nodes.length;
    _nodes.removeWhere((n) => n.id == id);
    if (_nodes.length != before) notifyListeners();
  }

  void clear() {
    if (_nodes.isEmpty) return;
    _nodes.clear();
    notifyListeners();
  }

  /// Replaces the entire scene.
  void replaceAll(Iterable<CanvasNode> nodes) {
    _nodes
      ..clear()
      ..addAll(nodes)
      ..sort((a, b) => a.z.compareTo(b.z));
    notifyListeners();
  }

  /// Brings [id] to the front (highest z).
  void bringToFront(String id) {
    final node = this[id];
    if (node == null) return;
    final maxZ =
        _nodes.isEmpty ? 0 : _nodes.map((n) => n.z).fold<int>(0, math.max);
    if (node.z >= maxZ && _nodes.last.id == id) return;
    upsert(node.copyWith(z: maxZ + 1));
  }

  /// Sends [id] to the back (lowest z).
  void sendToBack(String id) {
    final node = this[id];
    if (node == null) return;
    final minZ =
        _nodes.isEmpty ? 0 : _nodes.map((n) => n.z).fold<int>(0, math.min);
    upsert(node.copyWith(z: minZ - 1));
  }
}
