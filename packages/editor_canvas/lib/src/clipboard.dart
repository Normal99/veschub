/// Copy/paste utilities for the editor canvas.
library;

import 'package:flutter/widgets.dart';

import 'command_stack.dart';
import 'scene_model.dart';

/// Copies selected nodes to an in-memory clipboard.
class NodeClipboard {
  List<CanvasNode> _content = const [];

  List<CanvasNode> get content => List.unmodifiable(_content);

  void copy(Iterable<CanvasNode> nodes) {
    _content = nodes.toList();
  }

  bool get isEmpty => _content.isEmpty;

  /// Pastes clipboard content with [offset] applied, returning new nodes with
  /// fresh ids. The caller is expected to wrap the result in [AddNodeCommand]s.
  List<CanvasNode> paste(
    String Function() newId, {
    Offset offset = const Offset(20, 20),
  }) {
    return _content.map((n) {
      final t = n.transform.clone()
        // ignore: deprecated_member_use
        ..translate(offset.dx, offset.dy);
      return n.copyWith(id: newId(), transform: t);
    }).toList();
  }

  void clear() => _content = const [];
}

/// Generates sequential ids for pasted nodes.
class IdGenerator {
  int _counter = 0;
  String Function() prefix;

  IdGenerator([this.prefix = _defaultPrefix]);

  static String _defaultPrefix() => 'node';

  String next() => '${prefix()}_${++_counter}';
}
