/// Catalog of built-in node kinds for the flow editor.
///
/// Each [NodeKindDef] declares the input/output sockets a node of that kind
/// has, and an [evaluate] function the [GraphEvaluator] calls. This is where
/// you add new math/conditional/logic/state blocks.
library;

import 'dart:math' as math;

import 'package:dashboard_model/dashboard_model.dart';

import 'graph_model.dart';

/// The result of evaluating a node: a map of output-socket-id → value.
typedef NodeOutput = Map<String, dynamic>;

/// Evaluation context: provides input values and telemetry access.
typedef EvaluateFn = NodeOutput Function(NodeEvalContext ctx);

/// Context passed to each node's evaluator.
class NodeEvalContext {
  /// Input values keyed by input-socket-id.
  final Map<String, dynamic> inputs;

  /// A function to read a telemetry value by canonical key.
  final dynamic Function(String key) telemetry;

  const NodeEvalContext({required this.inputs, required this.telemetry});
}

/// Definition of a node kind: its sockets + evaluation logic.
class NodeKindDef {
  final String kind;
  final String displayName;
  final List<Socket> inputs;
  final List<Socket> outputs;
  final EvaluateFn evaluate;
  final CapabilityLevel level;

  const NodeKindDef({
    required this.kind,
    required this.displayName,
    required this.inputs,
    required this.outputs,
    required this.evaluate,
    this.level = CapabilityLevel.expert,
  });
}

/// A telemetry input node — reads a value from the store by key.
final telemetryNode = NodeKindDef(
  kind: 'telemetry',
  displayName: 'Telemetry',
  level: CapabilityLevel.expert,
  inputs: const [],
  outputs: const [Socket(id: 'value', label: 'Value', type: SocketType.any)],
  evaluate: (ctx) {
    // The telemetry key is stored as a node property, passed via inputs['key'].
    final key = ctx.inputs['key'] as String?;
    if (key == null) return const {};
    return {'value': ctx.telemetry(key)};
  },
);

/// A literal constant node — outputs a fixed value.
final literalNode = NodeKindDef(
  kind: 'literal',
  displayName: 'Constant',
  level: CapabilityLevel.expert,
  inputs: const [Socket(id: 'value', label: 'Value', type: SocketType.any)],
  outputs: const [Socket(id: 'value', label: 'Value', type: SocketType.any)],
  evaluate: (ctx) => {'value': ctx.inputs['value']},
);

/// Arithmetic: add/subtract/multiply/divide two numbers.
final mathNode = NodeKindDef(
  kind: 'math',
  displayName: 'Math',
  level: CapabilityLevel.expert,
  inputs: const [
    Socket(id: 'a', label: 'A', type: SocketType.number),
    Socket(id: 'b', label: 'B', type: SocketType.number),
    Socket(id: 'op', label: 'Op', type: SocketType.string),
  ],
  outputs: const [
    Socket(id: 'result', label: 'Result', type: SocketType.number),
  ],
  evaluate: (ctx) {
    final a = (ctx.inputs['a'] as num?)?.toDouble() ?? 0;
    final b = (ctx.inputs['b'] as num?)?.toDouble() ?? 0;
    final op = ctx.inputs['op'] as String? ?? 'add';
    final result = switch (op) {
      'add' => a + b,
      'sub' => a - b,
      'mul' => a * b,
      'div' => b == 0 ? double.nan : a / b,
      'mod' => b == 0 ? double.nan : a % b,
      'pow' => math.pow(a, b).toDouble(),
      _ => a + b,
    };
    return {'result': result};
  },
);

/// A comparison node: a vs b → boolean (lt, lte, gt, gte, eq, neq).
final compareNode = NodeKindDef(
  kind: 'compare',
  displayName: 'Compare',
  level: CapabilityLevel.expert,
  inputs: const [
    Socket(id: 'a', label: 'A', type: SocketType.any),
    Socket(id: 'b', label: 'B', type: SocketType.any),
    Socket(id: 'op', label: 'Op', type: SocketType.string),
  ],
  outputs: const [
    Socket(id: 'result', label: 'Result', type: SocketType.boolean),
  ],
  evaluate: (ctx) {
    final a = ctx.inputs['a'];
    final b = ctx.inputs['b'];
    final op = ctx.inputs['op'] as String? ?? 'lt';
    final na = (a as num?)?.toDouble();
    final nb = (b as num?)?.toDouble();
    final result = switch (op) {
      'lt' => na != null && nb != null && na < nb,
      'lte' => na != null && nb != null && na <= nb,
      'gt' => na != null && nb != null && na > nb,
      'gte' => na != null && nb != null && na >= nb,
      'eq' => a == b,
      'neq' => a != b,
      _ => false,
    };
    return {'result': result};
  },
);

/// A conditional (if/else) node: condition ? trueValue : falseValue.
final conditionalNode = NodeKindDef(
  kind: 'conditional',
  displayName: 'If/Else',
  level: CapabilityLevel.expert,
  inputs: const [
    Socket(id: 'condition', label: 'Cond', type: SocketType.boolean),
    Socket(id: 'trueValue', label: 'If true', type: SocketType.any),
    Socket(id: 'falseValue', label: 'If false', type: SocketType.any),
  ],
  outputs: const [Socket(id: 'result', label: 'Result', type: SocketType.any)],
  evaluate: (ctx) {
    final cond = ctx.inputs['condition'] as bool? ?? false;
    return {
      'result': cond ? ctx.inputs['trueValue'] : ctx.inputs['falseValue'],
    };
  },
);

/// A clamp node: clamps a value between min and max.
final clampNode = NodeKindDef(
  kind: 'clamp',
  displayName: 'Clamp',
  level: CapabilityLevel.expert,
  inputs: const [
    Socket(id: 'value', label: 'Value', type: SocketType.number),
    Socket(id: 'min', label: 'Min', type: SocketType.number),
    Socket(id: 'max', label: 'Max', type: SocketType.number),
  ],
  outputs: const [
    Socket(id: 'result', label: 'Result', type: SocketType.number),
  ],
  evaluate: (ctx) {
    final v = (ctx.inputs['value'] as num?)?.toDouble() ?? 0;
    final min = (ctx.inputs['min'] as num?)?.toDouble() ?? 0;
    final max = (ctx.inputs['max'] as num?)?.toDouble() ?? 1;
    return {'result': v.clamp(min, max)};
  },
);

/// A map/range node: linearly maps a value from [inMin, inMax] to [outMin, outMax].
final mapRangeNode = NodeKindDef(
  kind: 'mapRange',
  displayName: 'Map Range',
  level: CapabilityLevel.expert,
  inputs: const [
    Socket(id: 'value', label: 'Value', type: SocketType.number),
    Socket(id: 'inMin', label: 'In min', type: SocketType.number),
    Socket(id: 'inMax', label: 'In max', type: SocketType.number),
    Socket(id: 'outMin', label: 'Out min', type: SocketType.number),
    Socket(id: 'outMax', label: 'Out max', type: SocketType.number),
  ],
  outputs: const [
    Socket(id: 'result', label: 'Result', type: SocketType.number),
  ],
  evaluate: (ctx) {
    final v = (ctx.inputs['value'] as num?)?.toDouble() ?? 0;
    final inMin = (ctx.inputs['inMin'] as num?)?.toDouble() ?? 0;
    final inMax = (ctx.inputs['inMax'] as num?)?.toDouble() ?? 1;
    final outMin = (ctx.inputs['outMin'] as num?)?.toDouble() ?? 0;
    final outMax = (ctx.inputs['outMax'] as num?)?.toDouble() ?? 1;
    final inSpan = inMax - inMin;
    if (inSpan == 0) return {'result': outMin};
    final t = ((v - inMin) / inSpan).clamp(0.0, 1.0);
    return {'result': outMin + t * (outMax - outMin)};
  },
);

/// An output node — the final value the graph produces for a named output.
final outputNode = NodeKindDef(
  kind: 'output',
  displayName: 'Output',
  level: CapabilityLevel.expert,
  inputs: const [Socket(id: 'value', label: 'Value', type: SocketType.any)],
  outputs: const [],
  evaluate: (ctx) => const {},
);

/// All built-in node kinds, keyed by [NodeKindDef.kind].
final Map<String, NodeKindDef> builtInNodeKinds = {
  for (final k in [
    telemetryNode,
    literalNode,
    mathNode,
    compareNode,
    conditionalNode,
    clampNode,
    mapRangeNode,
    outputNode,
  ])
    k.kind: k,
};
