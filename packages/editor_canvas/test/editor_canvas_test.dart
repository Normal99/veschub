import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:editor_canvas/editor_canvas.dart';

CanvasNode _node(
  String id, {
  Offset t = Offset.zero,
  double scale = 1,
  int z = 0,
}) {
  return CanvasNode(
    id: id,
    transform: NodeTransforms.compose(translation: t, scale: scale),
    z: z,
  );
}

void main() {
  group('SceneModel', () {
    test('add keeps z-order sorted', () {
      final s = SceneModel();
      s.add(_node('a', z: 2));
      s.add(_node('b', z: 1));
      s.add(_node('c', z: 3));
      expect(s.nodes.map((n) => n.id).toList(), ['b', 'a', 'c']);
    });

    test('upsert replaces existing node', () {
      final s = SceneModel();
      s.add(_node('a', t: const Offset(10, 10)));
      s.upsert(_node('a', t: const Offset(50, 50)));
      expect(s.length, 1);
      expect(s['a']!.translation, const Offset(50, 50));
    });

    test('bringToFront raises z above all', () {
      final s = SceneModel();
      s.add(_node('a', z: 0));
      s.add(_node('b', z: 5));
      s.bringToFront('a');
      expect(s['a']!.z, greaterThan(s['b']!.z));
    });

    test('sendToBack lowers z below all', () {
      final s = SceneModel();
      s.add(_node('a', z: 5));
      s.add(_node('b', z: 0));
      s.sendToBack('a');
      expect(s['a']!.z, lessThan(s['b']!.z));
    });

    test('remove notifies', () {
      final s = SceneModel();
      var changed = 0;
      s.addListener(() => changed++);
      s.add(_node('a'));
      s.remove('a');
      expect(s.length, 0);
      expect(changed, greaterThanOrEqualTo(2));
    });
  });

  group('CommandStack', () {
    late SceneModel scene;
    late CommandStack stack;

    setUp(() {
      scene = SceneModel();
      stack = CommandStack(scene);
    });

    test('add then undo removes the node', () {
      stack.execute(AddNodeCommand(_node('a')));
      expect(scene.length, 1);
      stack.undo();
      expect(scene.length, 0);
      expect(stack.canUndo, isFalse);
      expect(stack.canRedo, isTrue);
    });

    test('redo re-applies after undo', () {
      stack.execute(AddNodeCommand(_node('a')));
      stack.undo();
      stack.redo();
      expect(scene.length, 1);
    });

    test('execute clears redo stack', () {
      stack.execute(AddNodeCommand(_node('a')));
      stack.undo();
      stack.execute(AddNodeCommand(_node('b')));
      expect(stack.canRedo, isFalse);
      expect(scene.length, 1);
      expect(scene['b'], isNotNull);
    });

    test('TransformNodesCommand moves and restores', () {
      final node = _node('a', t: const Offset(0, 0));
      scene.add(node);
      // ignore: deprecated_member_use
      final newT = node.transform.clone()..translate(100.0, 50.0);
      stack.execute(
        TransformNodesCommand({
          'a': (node.transform.clone(), newT),
        }),
      );
      expect(scene['a']!.translation, const Offset(100, 50));
      stack.undo();
      expect(scene['a']!.translation, Offset.zero);
    });

    test('labels reflect operation', () {
      stack.execute(AddNodeCommand(_node('widget_1')));
      expect(stack.undoLabel, contains('widget_1'));
    });
  });

  group('hitTest', () {
    test('finds topmost node under pointer', () {
      final nodes = [
        _node('back', t: const Offset(0, 0), z: 0),
        _node('front', t: const Offset(10, 10), z: 1),
      ];
      final hit = hitTest(
        nodes,
        const Offset(20, 20),
        (_) => 100,
        (_) => 100,
      );
      expect(hit, 'front');
    });

    test('returns null on empty space', () {
      final nodes = [_node('a', t: const Offset(0, 0))];
      final hit = hitTest(nodes, const Offset(500, 500), (_) => 50, (_) => 50);
      expect(hit, isNull);
    });

    test('hitTestRect selects overlapping nodes', () {
      final nodes = [
        _node('a', t: const Offset(0, 0)),
        _node('b', t: const Offset(100, 100)),
        _node('c', t: const Offset(500, 500)),
      ];
      final selected = hitTestRect(
        nodes,
        const Rect.fromLTWH(0, 0, 200, 200),
        (_) => 50,
        (_) => 50,
      );
      expect(selected, {'a', 'b'});
    });
  });

  group('snapping', () {
    test('grid snap rounds to nearest multiple', () {
      final result = snapTranslation(
        origin: Offset.zero,
        rawDelta: const Offset(13, 7),
        movingBounds: Rect.zero,
        otherBounds: const [],
        config:
            const SnapConfig(gridSize: 8, threshold: 4, enableGuides: false),
      );
      // 13 → 16 (within threshold 3), 7 → 8 (within threshold 1)
      expect(result.adjustedOffset, const Offset(16, 8));
    });

    test('guide snap aligns to other node edge', () {
      // moving node at x=0, other node left edge at x=100.
      final result = snapTranslation(
        origin: Offset.zero,
        rawDelta: const Offset(97, 0), // moving left would be 97, close to 100
        movingBounds: const Rect.fromLTWH(0, 0, 50, 50),
        otherBounds: const [Rect.fromLTWH(100, 0, 50, 50)],
        config: const SnapConfig(gridSize: 0, threshold: 4, enableGuides: true),
      );
      expect(result.adjustedOffset.dx, 100);
      expect(result.guides, isNotEmpty);
    });

    test('disabled config passes delta through', () {
      final result = snapTranslation(
        origin: Offset.zero,
        rawDelta: const Offset(123, 456),
        movingBounds: Rect.zero,
        otherBounds: const [],
        config: SnapConfig.disabled,
      );
      expect(result.adjustedOffset, const Offset(123, 456));
      expect(result.guides, isEmpty);
    });
  });

  group('SelectionModel', () {
    test('toggle adds then removes', () {
      final s = SelectionModel();
      s.toggle('a');
      expect(s.isSelected('a'), isTrue);
      s.toggle('a');
      expect(s.isSelected('a'), isFalse);
    });

    test('set replaces', () {
      final s = SelectionModel()..setAll(['a', 'b', 'c']);
      s.set('d');
      expect(s.ids, {'d'});
    });
  });

  group('NodeClipboard', () {
    test('paste applies offset and new ids', () {
      final clip = NodeClipboard();
      clip.copy([_node('a', t: const Offset(10, 10))]);
      var n = 0;
      final pasted = clip.paste(() => 'new_${++n}');
      expect(pasted, hasLength(1));
      expect(pasted.first.id, 'new_1');
      expect(pasted.first.translation, const Offset(30, 30));
    });
  });
}
