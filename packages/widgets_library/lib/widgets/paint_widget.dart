/// An Expert custom-paint widget that renders a [PaintProgram] from the
/// `paint_dsl` package via a [CustomPainter].
///
/// Resolved properties:
///  * `program` — a serialised [PaintProgram] (a JSON map). Required.
///  * Any other numeric property becomes a variable available to the program's
///    coordinate expressions (e.g. a `t` bound to telemetry feeds `"$t"`).
///
/// This is the "plug-in CustomPainter slot" from the plan: instead of shipping
/// a fixed set of painters, the dashboard document *is* the painter — a
/// declarative list of draw ops that can react to live telemetry.
library;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:paint_dsl/paint_dsl.dart';

/// Renders a `paint` widget from resolved properties.
class PaintWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const PaintWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final program = _decodeProgram(properties['program']);
    final vars = <String, double>{};
    for (final entry in properties.entries) {
      if (entry.key == 'program') continue;
      final v = entry.value;
      if (v is num) vars[entry.key] = v.toDouble();
    }

    return CustomPaint(
      painter: _PaintDslPainter(program: program, vars: vars),
      size: Size.infinite,
    );
  }

  PaintProgram _decodeProgram(Object? raw) {
    if (raw is Map) {
      try {
        return PaintProgram.fromJson(Map<String, dynamic>.from(raw));
      } catch (_) {
        return const PaintProgram();
      }
    }
    if (raw is PaintProgram) return raw;
    return const PaintProgram();
  }
}

class _PaintDslPainter extends CustomPainter {
  final PaintProgram program;
  final Map<String, double> vars;

  _PaintDslPainter({required this.program, required this.vars});

  @override
  void paint(Canvas canvas, Size size) {
    program.paint(canvas, size, vars);
  }

  @override
  bool shouldRepaint(covariant _PaintDslPainter old) =>
      old.program != program || !_mapsEqual(old.vars, vars);

  static bool _mapsEqual(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
