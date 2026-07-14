/// Veschub editor canvas — a reusable scene-graph editor with selection,
/// transform handles, snapping, z-order, copy/paste and undo/redo.
///
/// Decoupled from `dashboard_model`: operates on [CanvasNode]s carrying an
/// opaque payload; the studio layer converts to/from dashboard documents.
library;

export 'src/clipboard.dart';
export 'src/command_stack.dart';
export 'src/editor_canvas.dart';
export 'src/hit_test.dart';
export 'src/scene_model.dart';
export 'src/selection_model.dart';
export 'src/snapping.dart';
