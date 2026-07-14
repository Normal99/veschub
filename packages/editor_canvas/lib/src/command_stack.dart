/// Undo/redo command stack for the editor.
///
/// Commands are reverse-mutable operations on the [SceneModel]; each carries
/// enough state to undo itself. The [CommandStack] is a [ChangeNotifier] so
/// Riverpod/the UI can react to canUndo/canRedo changes.
library;

import 'package:flutter/widgets.dart';

import 'scene_model.dart';

/// A single reversible edit on the scene.
abstract class EditorCommand {
  /// Applies the edit. Must be idempotent-safe against re-application after an
  /// undo (i.e. apply/undo/apply cycles leave the scene consistent).
  void apply(SceneModel scene);

  /// Reverses the edit.
  void undo(SceneModel scene);

  /// Short label for the undo/redo menu.
  String get label;
}

/// Adds a node to the scene.
class AddNodeCommand extends EditorCommand {
  final CanvasNode node;
  AddNodeCommand(this.node);

  @override
  void apply(SceneModel scene) => scene.add(node);
  @override
  void undo(SceneModel scene) => scene.remove(node.id);
  @override
  String get label => 'Add ${node.id}';
}

/// Removes nodes by id.
class RemoveNodesCommand extends EditorCommand {
  final List<CanvasNode> removed;
  RemoveNodesCommand(this.removed);

  @override
  void apply(SceneModel scene) {
    for (final n in removed) {
      scene.remove(n.id);
    }
  }

  @override
  void undo(SceneModel scene) {
    for (final n in removed) {
      scene.add(n);
    }
  }

  @override
  String get label => removed.length == 1
      ? 'Delete ${removed.first.id}'
      : 'Delete ${removed.length} items';
}

/// Replaces a node's transform (move/scale/rotate).
class TransformNodesCommand extends EditorCommand {
  /// Map of nodeId → (oldTransform, newTransform).
  final Map<String, (Matrix4, Matrix4)> changes;

  TransformNodesCommand(this.changes);

  @override
  void apply(SceneModel scene) {
    for (final entry in changes.entries) {
      final node = scene[entry.key];
      if (node != null) {
        scene.upsert(node.copyWith(transform: entry.value.$2));
      }
    }
  }

  @override
  void undo(SceneModel scene) {
    for (final entry in changes.entries) {
      final node = scene[entry.key];
      if (node != null) {
        scene.upsert(node.copyWith(transform: entry.value.$1));
      }
    }
  }

  @override
  String get label => changes.length == 1
      ? 'Move ${changes.keys.first}'
      : 'Move ${changes.length} items';
}

/// Reorders z (bring to front / send to back).
class ReorderCommand extends EditorCommand {
  final String id;
  final int oldZ;
  final int newZ;
  ReorderCommand({required this.id, required this.oldZ, required this.newZ});

  @override
  void apply(SceneModel scene) {
    final node = scene[id];
    if (node != null) scene.upsert(node.copyWith(z: newZ));
  }

  @override
  void undo(SceneModel scene) {
    final node = scene[id];
    if (node != null) scene.upsert(node.copyWith(z: oldZ));
  }

  @override
  String get label => 'Reorder $id';
}

/// Replaces a node's opaque [CanvasNode.data] payload (e.g. a `WidgetInstance`
/// whose bound properties changed in the inspector). Keeps the transform and
/// z-order intact; only the payload is swapped, so the editor never needs to
/// understand the payload's structure.
class UpdateNodeDataCommand extends EditorCommand {
  final String id;
  final Object? oldData;
  final Object? newData;

  UpdateNodeDataCommand({
    required this.id,
    required this.oldData,
    required this.newData,
  });

  @override
  void apply(SceneModel scene) {
    final node = scene[id];
    if (node != null) scene.upsert(node.copyWith(data: newData));
  }

  @override
  void undo(SceneModel scene) {
    final node = scene[id];
    if (node != null) scene.upsert(node.copyWith(data: oldData));
  }

  @override
  String get label => 'Edit $id';
}

/// An undo/redo history stack bound to a [SceneModel].
class CommandStack extends ChangeNotifier {
  CommandStack(this._scene);

  final SceneModel _scene;
  final List<EditorCommand> _undo = [];
  final List<EditorCommand> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  String? get undoLabel => _undo.isEmpty ? null : _undo.last.label;
  String? get redoLabel => _redo.isEmpty ? null : _redo.last.label;

  /// Executes [command], applies it to the scene, and pushes it onto the
  /// undo stack. Clears the redo stack (branching history).
  void execute(EditorCommand command) {
    command.apply(_scene);
    _undo.add(command);
    _redo.clear();
    notifyListeners();
  }

  void undo() {
    if (_undo.isEmpty) return;
    final cmd = _undo.removeLast();
    cmd.undo(_scene);
    _redo.add(cmd);
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final cmd = _redo.removeLast();
    cmd.apply(_scene);
    _undo.add(cmd);
    notifyListeners();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
    notifyListeners();
  }
}
