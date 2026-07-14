/// Declarative custom-paint DSL for Expert dashboards.
///
/// A [PaintProgram] is a serialisable list of [PaintOp] drawing primitives
/// executed against a Flutter `Canvas`. The `paint` widget kind (in
/// `widgets_library`) stores a program as a literal binding and renders it via
/// a `CustomPainter`; numeric coordinates can reference bound telemetry values
/// by name for live reactive painting.
library;

export 'src/paint_op.dart';
export 'src/paint_program.dart' show PaintProgram, resolveExpr;
