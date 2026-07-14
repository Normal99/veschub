/// Veschub node_graph — dataflow editor for Expert binding mode.
///
/// Defines typed nodes (telemetry input, math, compare, conditional, clamp,
/// map-range, output), a topological evaluator, and a serializable [FlowGraph]
/// model persisted in the dashboard document's `graphs` field.
library;

export 'src/graph_evaluator.dart';
export 'src/graph_model.dart';
export 'src/graph_point.dart';
export 'src/node_catalog.dart';
