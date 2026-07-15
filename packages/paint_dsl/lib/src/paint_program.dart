/// A paint program: an ordered list of [PaintOp]s plus the interpreter that
/// executes them against a Flutter [Canvas].
///
/// The `paint` widget kind stores a `PaintProgram` (serialised as JSON) in its
/// `program` property. At render time the widget builds a variable map from
/// its other resolved properties (every numeric property becomes a variable
/// keyed by its name) and calls [PaintProgram.paint].
library;

import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'paint_op.dart';

part 'paint_program.freezed.dart';
part 'paint_program.g.dart';

/// A serialisable paint program: a sequence of [PaintOp]s.
@freezed
class PaintProgram with _$PaintProgram {
  const PaintProgram._();

  @JsonSerializable(explicitToJson: true)
  const factory PaintProgram({
    @JsonKey(name: 'ops') @Default(<PaintOp>[]) List<PaintOp> ops,
  }) = _PaintProgram;

  factory PaintProgram.fromJson(Map<String, dynamic> json) =>
      _$PaintProgramFromJson(json);

  /// Executes the program against [canvas] of logical [size], resolving any
  /// variable references from [vars]. The caller owns save/restore of the
  /// outer canvas state.
  void paint(ui.Canvas canvas, ui.Size size, Map<String, double> vars) {
    PaintProgramInterpreter(this, canvas, size, vars).run();
  }
}

/// Resolves a [PaintExpr] to a concrete [double].
///
/// A [num] is returned as a double. A [String] is treated as a variable
/// reference: a leading `$` is stripped, then the value is looked up in
/// [vars] (missing keys resolve to 0). Anything else is 0.
double resolveExpr(PaintExpr expr, Map<String, double> vars) {
  double result;
  if (expr is num) {
    result = expr.toDouble();
  } else if (expr is String) {
    final name = expr.startsWith('\$') ? expr.substring(1) : expr;
    result = vars[name] ?? 0;
  } else {
    result = 0;
  }
  if (result.isNaN || result.isInfinite) return 0.0;
  return result;
}

/// Internal interpreter that walks the op list and draws.
class PaintProgramInterpreter {
  PaintProgramInterpreter(this.program, this.canvas, this.size, this.vars);

  final PaintProgram program;
  final ui.Canvas canvas;
  final ui.Size size;
  final Map<String, double> vars;

  Paint _brush = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1
    ..strokeCap = StrokeCap.round;

  void run() {
    for (final op in program.ops) {
      _exec(op);
    }
  }

  void _exec(PaintOp op) {
    switch (op) {
      case BrushOp(
          :final color,
          :final strokeWidth,
          :final style,
          :final cap,
          :final alpha
        ):
        final a =
            alpha == null ? 1.0 : resolveExpr(alpha, vars).clamp(0.0, 1.0);
        _brush = Paint()
          ..color = Color(color).withValues(alpha: a)
          ..style = style == PaintFill.fill
              ? PaintingStyle.fill
              : PaintingStyle.stroke
          ..strokeWidth = resolveExpr(strokeWidth, vars)
          ..strokeCap = switch (cap) {
            PaintCap.round => StrokeCap.round,
            PaintCap.butt => StrokeCap.butt,
            PaintCap.square => StrokeCap.square,
          };
      case ClearOp(:final color):
        canvas.drawRect(
          ui.Offset.zero & size,
          Paint()..color = Color(color),
        );
      case LineOp(:final x1, :final y1, :final x2, :final y2):
        canvas.drawLine(
          ui.Offset(resolveExpr(x1, vars), resolveExpr(y1, vars)),
          ui.Offset(resolveExpr(x2, vars), resolveExpr(y2, vars)),
          _brush,
        );
      case RectOp(:final x, :final y, :final w, :final h):
        canvas.drawRect(
          ui.Rect.fromLTWH(
            resolveExpr(x, vars),
            resolveExpr(y, vars),
            resolveExpr(w, vars),
            resolveExpr(h, vars),
          ),
          _brush,
        );
      case RrectOp(:final x, :final y, :final w, :final h, :final r):
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            ui.Rect.fromLTWH(
              resolveExpr(x, vars),
              resolveExpr(y, vars),
              resolveExpr(w, vars),
              resolveExpr(h, vars),
            ),
            ui.Radius.circular(resolveExpr(r, vars)),
          ),
          _brush,
        );
      case CircleOp(:final cx, :final cy, :final r):
        canvas.drawCircle(
          ui.Offset(resolveExpr(cx, vars), resolveExpr(cy, vars)),
          resolveExpr(r, vars),
          _brush,
        );
      case OvalOp(:final x, :final y, :final w, :final h):
        canvas.drawOval(
          ui.Rect.fromLTWH(
            resolveExpr(x, vars),
            resolveExpr(y, vars),
            resolveExpr(w, vars),
            resolveExpr(h, vars),
          ),
          _brush,
        );
      case ArcOp(
          :final cx,
          :final cy,
          :final r,
          :final start,
          :final sweep,
          :final useCenter,
        ):
        final radius = resolveExpr(r, vars);
        canvas.drawArc(
          ui.Rect.fromCircle(
            center: ui.Offset(resolveExpr(cx, vars), resolveExpr(cy, vars)),
            radius: radius,
          ),
          resolveExpr(start, vars),
          resolveExpr(sweep, vars),
          useCenter,
          _brush,
        );
      case PathOp(:final points, :final close):
        if (points.isEmpty) break;
        if (points.any((p) => p.length < 2)) break;
        final path = ui.Path();
        final first = points.first;
        path.moveTo(
          resolveExpr(first[0], vars),
          resolveExpr(first[1], vars),
        );
        for (var i = 1; i < points.length; i++) {
          final p = points[i];
          path.lineTo(resolveExpr(p[0], vars), resolveExpr(p[1], vars));
        }
        if (close) path.close();
        canvas.drawPath(path, _brush);
      case TextOp(
          :final x,
          :final y,
          :final text,
          :final fontSize,
          :final color
        ):
        final tp = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: color != null ? Color(color) : _brush.color,
              fontSize: resolveExpr(fontSize, vars),
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, ui.Offset(resolveExpr(x, vars), resolveExpr(y, vars)));
      case SaveOp():
        canvas.save();
      case RestoreOp():
        canvas.restore();
      case TranslateOp(:final x, :final y):
        canvas.translate(resolveExpr(x, vars), resolveExpr(y, vars));
      case RotateOp(:final radians):
        canvas.rotate(resolveExpr(radians, vars));
      case ScaleOp(:final sx, :final sy):
        canvas.scale(resolveExpr(sx, vars), resolveExpr(sy, vars));
    }
  }
}
