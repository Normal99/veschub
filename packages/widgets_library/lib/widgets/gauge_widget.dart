/// An arc gauge widget drawn with [CustomPainter] — a needle/sweep from `min`
/// to `value` against `max`, with optional ticks and a digital readout.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

/// Renders a `gauge` widget from resolved properties:
///  * `value`  — current value (num)
///  * `min`    — scale minimum (num, default 0)
///  * `max`    — scale maximum (num, default 1)
///  * `label`  — optional caption
///  * `unit`   — optional unit suffix on the readout
///  * `color`   — arc/needle colour (ARGB int)
///  * `accent`  — tick/secondary colour (ARGB int)
class GaugeWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const GaugeWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final value = (properties['value'] as num?)?.toDouble() ?? 0;
    final min = (properties['min'] as num?)?.toDouble() ?? 0;
    final max = (properties['max'] as num?)?.toDouble() ?? 1;
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFFFFFFFF);
    final label = properties['label'] as String?;
    final unit = properties['unit'] as String?;

    final span = (max - min) == 0 ? 1.0 : (max - min);
    final t = ((value - min) / span).clamp(0.0, 1.0);

    return CustomPaint(
      painter: _GaugePainter(
        t: t,
        color: color,
        trackColor: color.withValues(alpha: 0.18),
        accent: accent,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _format(value),
              style: TextStyle(
                color: color,
                fontSize: 32,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (unit != null || label != null)
              Text(
                [label, unit].whereType<String>().join(' · '),
                style: TextStyle(
                  color: accent.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _format(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _GaugePainter extends CustomPainter {
  final double t;
  final Color color;
  final Color trackColor;
  final Color accent;

  _GaugePainter({
    required this.t,
    required this.color,
    required this.trackColor,
    required this.accent,
  });

  static const _sweep = 270.0; // degrees of arc
  static const _startAngle = 135.0; // bottom-left

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(0.0, (size.shortestSide / 2) - 8);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;

    const start = _startAngle * math.pi / 180;
    const full = _sweep * math.pi / 180;
    canvas.drawArc(rect, start, full, false, track);
    canvas.drawArc(rect, start, full * t, false, arc);

    // Ticks
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.6);
    const steps = 10;
    for (var i = 0; i <= steps; i++) {
      final a = start + (full * i / steps);
      final outer = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
      final inner = center +
          Offset(math.cos(a) * (radius - 8), math.sin(a) * (radius - 8));
      canvas.drawLine(inner, outer, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.t != t || old.color != color || old.accent != accent;
}
