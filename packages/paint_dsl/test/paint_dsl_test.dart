import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:paint_dsl/paint_dsl.dart';

void main() {
  group('resolveExpr', () {
    test('num literal → double', () {
      expect(resolveExpr(42, {}), 42.0);
      expect(resolveExpr(3.5, {}), 3.5);
    });

    test('string var-ref resolves from vars', () {
      expect(resolveExpr('erpm', {'erpm': 1234}), 1234.0);
      expect(resolveExpr('\$erpm', {'erpm': 1234}), 1234.0);
    });

    test('missing var resolves to 0', () {
      expect(resolveExpr('nope', {}), 0);
    });

    test('other types resolve to 0', () {
      expect(resolveExpr(true, {}), 0);
      expect(resolveExpr(<Object>[], {}), 0);
    });
  });

  group('PaintOp serialization', () {
    test('brush op round-trips', () {
      const op =
          BrushOp(color: 0xFF00FF00, strokeWidth: 2.5, style: PaintFill.fill);
      final json = op.toJson();
      final back = PaintOp.fromJson(json);
      expect(back, isA<BrushOp>());
      final b = back as BrushOp;
      expect(b.color, 0xFF00FF00);
      expect(b.strokeWidth, 2.5);
      expect(b.style, PaintFill.fill);
    });

    test('circle op with var-ref round-trips', () {
      const op = CircleOp(cx: '\$x', cy: 10, r: 'r');
      final back = PaintOp.fromJson(op.toJson());
      expect(back, isA<CircleOp>());
      final c = back as CircleOp;
      expect(c.cx, '\$x');
      expect(c.cy, 10);
      expect(c.r, 'r');
    });

    test('path op round-trips points', () {
      const op = PathOp(
        points: [
          [0, 0],
          [10, 20],
          ['\$x', 30],
        ],
        close: true,
      );
      final back = PaintOp.fromJson(op.toJson()) as PathOp;
      expect(back.points.length, 3);
      expect(back.points[2][0], '\$x');
      expect(back.close, true);
    });

    test('text op round-trips', () {
      const op =
          TextOp(x: 5, y: 5, text: 'hello', fontSize: 18, color: 0xFFFFFFFF);
      final back = PaintOp.fromJson(op.toJson()) as TextOp;
      expect(back.text, 'hello');
      expect(back.fontSize, 18);
    });
  });

  group('PaintProgram serialization', () {
    test('full program round-trips and preserves order', () {
      const program = PaintProgram(
        ops: [
          BrushOp(color: 0xFF112233),
          ClearOp(color: 0xFF000000),
          LineOp(x1: 0, y1: 0, x2: 100, y2: 100),
          SaveOp(),
          TranslateOp(x: 50, y: 50),
          CircleOp(cx: 0, cy: 0, r: '\$r'),
          RestoreOp(),
        ],
      );
      final json = program.toJson();
      final back = PaintProgram.fromJson(json);
      expect(back.ops.length, 7);
      expect(back.ops[0], isA<BrushOp>());
      expect(back.ops[3], isA<SaveOp>());
      expect(back.ops[5], isA<CircleOp>());
    });
  });

  group('PaintProgram.paint', () {
    test('executes a non-trivial program without throwing', () {
      const program = PaintProgram(
        ops: [
          ClearOp(color: 0xFF101010),
          BrushOp(color: 0xFFFF0000, style: PaintFill.fill),
          RectOp(x: 0, y: 0, w: 100, h: 100),
          BrushOp(color: 0xFF00FF00, style: PaintFill.stroke, strokeWidth: 3),
          CircleOp(cx: 50, cy: 50, r: 25),
          SaveOp(),
          TranslateOp(x: 50, y: 50),
          RotateOp(radians: 0.5),
          LineOp(x1: 0, y1: 0, x2: 40, y2: 0),
          RestoreOp(),
          PathOp(
            points: [
              [0, 0],
              [10, 0],
              [10, 10],
            ],
            close: true,
          ),
          TextOp(x: 0, y: 0, text: 'hi', fontSize: 12),
          ArcOp(cx: 50, cy: 50, r: 10, start: 0, sweep: 1.5),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      program.paint(canvas, const ui.Size(200, 200), {'r': 12});
      final picture = recorder.endRecording();
      expect(picture, isA<ui.Picture>());
    });

    test('variable refs resolve at paint time', () {
      const program = PaintProgram(
        ops: [
          BrushOp(color: 0xFFFFFFFF),
          CircleOp(cx: '\$cx', cy: '\$cy', r: '\$r'),
        ],
      );
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      program.paint(canvas, const ui.Size(100, 100), {
        'cx': 50,
        'cy': 50,
        'r': 20,
      });
      expect(recorder.endRecording(), isA<ui.Picture>());
    });

    test('empty program is a no-op', () {
      const program = PaintProgram();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      program.paint(canvas, const ui.Size(10, 10), const {});
      expect(recorder.endRecording(), isA<ui.Picture>());
    });
  });
}
