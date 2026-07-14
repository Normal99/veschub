/// Declarative paint operations — the "instructions" of the custom-paint DSL.
///
/// Each [PaintOp] is one drawing primitive (line, rect, circle, arc, text…)
/// plus transform stack ops (save/restore/translate/rotate/scale) and a
/// [BrushOp] that configures the current paint. A dashboard's `paint` widget
/// stores a [PaintProgram] (a list of ops) as a literal binding; the runtime
/// executes them against a `Canvas` inside a `CustomPainter`.
///
/// ## Variable references
///
/// Any numeric coordinate may be either a literal [num] or a [String] variable
/// reference. A string like `"$erpm"` (or bare `"erpm"`) is resolved at paint
/// time from the widget's resolved properties (every non-`program` property is
/// exposed as a variable by its key). This lets a custom painter react to live
/// telemetry — e.g. a needle whose angle is `"$t"` where `t` is a normalised
/// telemetry value bound through the inspector.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'paint_op.freezed.dart';
part 'paint_op.g.dart';

/// A numeric expression: a literal [num] or a variable reference [String].
///
/// Stored as `Object` for ergonomic JSON hand-authoring (`42`, `"$erpm"`).
typedef PaintExpr = Object;

/// How a stroked path is terminated.
enum PaintCap { round, butt, square }

/// Whether a shape is filled or stroked.
enum PaintFill { fill, stroke }

/// Configures the current paint used by subsequent draw ops.
@freezed
sealed class PaintOp with _$PaintOp {
  const PaintOp._();

  /// Sets the active brush. Applies until the next [BrushOp].
  ///
  /// `color` is an ARGB int (0xAARRGGBB). `alpha` (0..1) optionally overrides
  /// the colour's alpha channel.
  const factory PaintOp.brush({
    @JsonKey(name: 'color') @Default(0xFFFFFFFF) int color,
    @JsonKey(name: 'stroke_width') @Default(1.0) PaintExpr strokeWidth,
    @JsonKey(name: 'style') @Default(PaintFill.stroke) PaintFill style,
    @JsonKey(name: 'cap') @Default(PaintCap.round) PaintCap cap,
    @JsonKey(name: 'alpha') PaintExpr? alpha,
  }) = BrushOp;

  /// Fills the entire canvas with [color].
  const factory PaintOp.clear({
    @JsonKey(name: 'color') @Default(0xFF000000) int color,
  }) = ClearOp;

  /// Draws a straight line from (x1,y1) to (x2,y2).
  const factory PaintOp.line({
    @JsonKey(name: 'x1') @Default(0) PaintExpr x1,
    @JsonKey(name: 'y1') @Default(0) PaintExpr y1,
    @JsonKey(name: 'x2') @Default(0) PaintExpr x2,
    @JsonKey(name: 'y2') @Default(0) PaintExpr y2,
  }) = LineOp;

  /// Draws a rectangle at (x,y) with size (w,h).
  const factory PaintOp.rect({
    @JsonKey(name: 'x') @Default(0) PaintExpr x,
    @JsonKey(name: 'y') @Default(0) PaintExpr y,
    @JsonKey(name: 'w') @Default(0) PaintExpr w,
    @JsonKey(name: 'h') @Default(0) PaintExpr h,
  }) = RectOp;

  /// Draws a rounded rectangle with corner radius [r].
  const factory PaintOp.rrect({
    @JsonKey(name: 'x') @Default(0) PaintExpr x,
    @JsonKey(name: 'y') @Default(0) PaintExpr y,
    @JsonKey(name: 'w') @Default(0) PaintExpr w,
    @JsonKey(name: 'h') @Default(0) PaintExpr h,
    @JsonKey(name: 'r') @Default(0) PaintExpr r,
  }) = RrectOp;

  /// Draws a circle at (cx,cy) with radius [r].
  const factory PaintOp.circle({
    @JsonKey(name: 'cx') @Default(0) PaintExpr cx,
    @JsonKey(name: 'cy') @Default(0) PaintExpr cy,
    @JsonKey(name: 'r') @Default(0) PaintExpr r,
  }) = CircleOp;

  /// Draws an ellipse inscribed in the rect (x,y,w,h).
  const factory PaintOp.oval({
    @JsonKey(name: 'x') @Default(0) PaintExpr x,
    @JsonKey(name: 'y') @Default(0) PaintExpr y,
    @JsonKey(name: 'w') @Default(0) PaintExpr w,
    @JsonKey(name: 'h') @Default(0) PaintExpr h,
  }) = OvalOp;

  /// Draws an arc on a circle of radius [r] at (cx,cy). Angles are in
  /// radians; [sweep] is the angular extent drawn from [start].
  const factory PaintOp.arc({
    @JsonKey(name: 'cx') @Default(0) PaintExpr cx,
    @JsonKey(name: 'cy') @Default(0) PaintExpr cy,
    @JsonKey(name: 'r') @Default(0) PaintExpr r,
    @JsonKey(name: 'start') @Default(0) PaintExpr start,
    @JsonKey(name: 'sweep') @Default(0) PaintExpr sweep,
    @JsonKey(name: 'use_center') @Default(false) bool useCenter,
  }) = ArcOp;

  /// Draws a polyline through [points] (each `[x, y]`). If [close] is true the
  /// path is closed back to the first point.
  const factory PaintOp.path({
    @JsonKey(name: 'points')
    @Default(<List<PaintExpr>>[])
    List<List<PaintExpr>> points,
    @JsonKey(name: 'close') @Default(false) bool close,
  }) = PathOp;

  /// Draws [text] at (x,y). Drawn with the current brush colour.
  const factory PaintOp.text({
    @JsonKey(name: 'x') @Default(0) PaintExpr x,
    @JsonKey(name: 'y') @Default(0) PaintExpr y,
    @JsonKey(name: 'text') @Default('') String text,
    @JsonKey(name: 'font_size') @Default(14.0) PaintExpr fontSize,
    @JsonKey(name: 'color') int? color,
  }) = TextOp;

  /// Pushes the current transform onto the stack.
  const factory PaintOp.save() = SaveOp;

  /// Restores the most recently saved transform.
  const factory PaintOp.restore() = RestoreOp;

  /// Translates the canvas by (x,y).
  const factory PaintOp.translate({
    @JsonKey(name: 'x') @Default(0) PaintExpr x,
    @JsonKey(name: 'y') @Default(0) PaintExpr y,
  }) = TranslateOp;

  /// Rotates the canvas by [radians] about the origin.
  const factory PaintOp.rotate({
    @JsonKey(name: 'radians') @Default(0) PaintExpr radians,
  }) = RotateOp;

  /// Scales the canvas by (sx, sy).
  const factory PaintOp.scale({
    @JsonKey(name: 'sx') @Default(1.0) PaintExpr sx,
    @JsonKey(name: 'sy') @Default(1.0) PaintExpr sy,
  }) = ScaleOp;

  factory PaintOp.fromJson(Map<String, dynamic> json) =>
      _$PaintOpFromJson(json);
}
