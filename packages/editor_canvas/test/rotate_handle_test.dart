// Drives the new drag-to-rotate handle directly on EditorCanvas (rather than
// through the full Studio app) so the exact pixel position of the handle —
// derived the same way the widget itself computes it — is fully controlled.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:editor_canvas/editor_canvas.dart';

void main() {
  // A single 100x100 node whose local origin sits at canvas (100, 100), so
  // its centre is (150, 150) and its rotate handle (local (w/2, -24)) sits
  // at (150, 76) before any rotation.
  const nodeId = 'n1';
  const nodeSize = 100.0;
  const handleDistance = 24.0;

  SceneModel buildScene() {
    final scene = SceneModel();
    scene.add(CanvasNode(
      id: nodeId,
      transform: NodeTransforms.compose(translation: const Offset(100, 100)),
    ));
    return scene;
  }

  Widget host(SceneModel scene, SelectionModel selection, CommandStack commands) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 400,
        height: 400,
        child: EditorCanvas(
          scene: scene,
          selection: selection,
          commands: commands,
          nodeBuilder: (node) => const ColoredBox(color: Colors.blue),
          nodeWidth: (_) => nodeSize,
          nodeHeight: (_) => nodeSize,
        ),
      ),
    );
  }

  testWidgets('dragging the rotate handle rotates the selected node',
      (tester) async {
    final scene = buildScene();
    final selection = SelectionModel()..set(nodeId);
    final commands = CommandStack(scene);

    await tester.pumpWidget(host(scene, selection, commands));
    await tester.pump();

    const pivot = Offset(150, 150);
    const handleStart = Offset(150, 150 - nodeSize / 2 - handleDistance);
    // Drag the handle to the pivot's right (90° clockwise from "up").
    final handleEnd = pivot + const Offset(74, 0);

    final gesture = await tester.startGesture(handleStart);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(handleEnd);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.up();
    await tester.pumpAndSettle();

    final node = scene[nodeId]!;
    final a = node.transform.entry(0, 0);
    final b = node.transform.entry(1, 0);
    final angle = math.atan2(b, a);
    // Expect roughly a 90 degree (pi/2) rotation.
    expect(angle, closeTo(math.pi / 2, 0.05));

    // And it went through the command stack (undoable).
    expect(commands.canUndo, isTrue);
  });

  testWidgets('rotate handle is not shown or hit-testable for multi-select',
      (tester) async {
    final scene = SceneModel()
      ..add(CanvasNode(
        id: nodeId,
        transform: NodeTransforms.compose(translation: const Offset(100, 100)),
      ))
      ..add(CanvasNode(
        id: 'n2',
        transform: NodeTransforms.compose(translation: const Offset(250, 100)),
      ));
    final selection = SelectionModel()..setAll({nodeId, 'n2'});
    final commands = CommandStack(scene);

    await tester.pumpWidget(host(scene, selection, commands));
    await tester.pump();

    const handleStart = Offset(150, 150 - nodeSize / 2 - handleDistance);
    final gesture = await tester.startGesture(handleStart);
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.moveTo(const Offset(300, 150));
    await tester.pump(const Duration(milliseconds: 20));
    await gesture.up();
    await tester.pumpAndSettle();

    // Nothing should have rotated — with 2+ selected, that point is just
    // empty space above the shape, so this was a no-op marquee drag.
    final node = scene[nodeId]!;
    expect(node.transform.entry(1, 0), closeTo(0, 1e-9));
  });
}
