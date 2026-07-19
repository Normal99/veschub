/// An arc gauge widget drawn with [CustomPainter] — a needle/sweep from `min`
/// to `value` against `max`, with optional ticks and a digital readout.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

import '../src/cosmetic_helpers.dart';

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
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 32.0;

    final span = (max - min) == 0 ? 1.0 : (max - min);
    final t = ((value - min) / span).clamp(0.0, 1.0);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: CustomPaint(
            painter: _GaugePainter(
              t: t,
              color: color,
              trackColor: color.withValues(alpha: 0.18),
              accent: accent,
              tickCount: (properties['tickCount'] as num?)?.toInt() ?? 10,
              sweepAngle: (properties['sweepAngle'] as num?)?.toDouble() ?? 270,
              startAngle: (properties['startAngle'] as num?)?.toDouble() ?? 135,
              arcWidth: (properties['arcWidth'] as num?)?.toDouble() ?? 10,
              needleStyle: properties['needleStyle'] as String? ?? 'arc',
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _format(value),
                    style: applyTextStyle(
                      TextStyle(
                        color: color,
                        fontSize: fontSizeRaw.toDouble(),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      properties,
                    ),
                  ),
                  if (unit != null || label != null)
                    Text(
                      [label, unit].whereType<String>().join(' · '),
                      style: applyTextStyle(
                        TextStyle(
                          color: accent.withValues(alpha: 0.8),
                          fontSize: (fontSizeRaw.toDouble() * 0.38).clamp(9, 14),
                        ),
                        properties,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      properties,
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
  final int tickCount;
  final double sweepAngle;
  final double startAngle;
  final double arcWidth;
  final String needleStyle;

  _GaugePainter({
    required this.t,
    required this.color,
    required this.trackColor,
    required this.accent,
    required this.tickCount,
    required this.sweepAngle,
    required this.startAngle,
    required this.arcWidth,
    required this.needleStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(0.0, (size.shortestSide / 2) - 8);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcWidth
      ..strokeCap = StrokeCap.round
      ..color = color;

    final start = (startAngle - 90) * math.pi / 180;
    final full = sweepAngle * math.pi / 180;
    canvas.drawArc(rect, start, full, false, track);
    canvas.drawArc(rect, start, full * t, false, arc);

    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = accent.withValues(alpha: 0.6);
    if (tickCount > 1) {
      for (var i = 0; i <= tickCount; i++) {
        final a = start + (full * i / tickCount);
        final outer = center + Offset(math.cos(a) * radius, math.sin(a) * radius);
        final inner = center +
            Offset(math.cos(a) * (radius - 8), math.sin(a) * (radius - 8));
        canvas.drawLine(inner, outer, tick);
      }
    }

    if (needleStyle == 'needle') {
      final a = start + full * t;
      final tip = center + Offset(math.cos(a) * (radius - 20), math.sin(a) * (radius - 20));
      final needle = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(center.dx - 4, center.dy)
        ..lineTo(center.dx + 4, center.dy)
        ..close();
      canvas.drawPath(path, needle);
      canvas.drawCircle(center, 4, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.t != t ||
      old.color != color ||
      old.accent != accent ||
      old.tickCount != tickCount ||
      old.sweepAngle != sweepAngle ||
      old.startAngle != startAngle ||
      old.arcWidth != arcWidth ||
      old.needleStyle != needleStyle;
}
