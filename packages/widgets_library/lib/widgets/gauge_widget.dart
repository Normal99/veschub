library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

import '../src/cosmetic_helpers.dart';

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

    final centerValue = (properties['centerValue'] as num?)?.toDouble() ?? value;
    final centerUnit = properties['centerUnit'] as String? ?? unit;
    final subLabel = properties['subLabel'] as String?;
    final showCenterText = properties['showCenterText'] as bool? ?? false;
    final showTickLabels = properties['showTickLabels'] as bool? ?? false;

    final innerValue = (properties['innerValue'] as num?)?.toDouble();
    final innerMin = (properties['innerMin'] as num?)?.toDouble() ?? 0;
    final innerMax = (properties['innerMax'] as num?)?.toDouble() ?? 1;
    final innerColor = Color((properties['innerColor'] as int?) ?? 0xFF888888);
    final innerArcWidth = (properties['innerArcWidth'] as num?)?.toDouble() ?? 4;
    final showInnerRing = innerValue != null;

    final redlineStart = (properties['redlineStart'] as num?)?.toDouble();
    final redlineColor = Color((properties['redlineColor'] as int?) ?? 0xFFFF0000);
    final showRedline = redlineStart != null;

    final span = (max - min) == 0 ? 1.0 : (max - min);
    final t = ((value - min) / span).clamp(0.0, 1.0);
    final innerT = showInnerRing
        ? (((innerValue! - innerMin) / ((innerMax - innerMin) == 0 ? 1.0 : (innerMax - innerMin))).clamp(0.0, 1.0))
        : 0.0;

    final sweepAngle = (properties['sweepAngle'] as num?)?.toDouble() ?? 270;
    final startAngle = (properties['startAngle'] as num?)?.toDouble() ?? 135;
    final arcWidth = (properties['arcWidth'] as num?)?.toDouble() ?? 10;
    final needleStyle = properties['needleStyle'] as String? ?? 'arc';
    final tickCount = (properties['tickCount'] as num?)?.toInt() ?? 10;

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: CustomPaint(
            painter: _GaugePainter(
              t: t,
              innerT: innerT,
              color: color,
              trackColor: color.withValues(alpha: 0.18),
              accent: accent,
              innerColor: innerColor,
              innerTrackColor: innerColor.withValues(alpha: 0.15),
              tickCount: tickCount,
              sweepAngle: sweepAngle,
              startAngle: startAngle,
              arcWidth: arcWidth,
              innerArcWidth: innerArcWidth,
              needleStyle: needleStyle,
              showInnerRing: showInnerRing,
              showRedline: showRedline,
              redlineStart: redlineStart ?? 0.0,
              redlineColor: redlineColor,
              showTickLabels: showTickLabels,
              min: min,
              max: max,
              tickLabelColor: accent.withValues(alpha: 0.7),
            ),
            child: showCenterText
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _format(centerValue),
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
                        if (centerUnit != null || subLabel != null)
                          Text(
                            [centerUnit, subLabel].whereType<String>().join(' '),
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.7),
                              fontSize: (fontSizeRaw.toDouble() * 0.35).clamp(9, 14),
                            ),
                          ),
                      ],
                    ),
                  )
                : Padding(
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
  final double innerT;
  final Color color;
  final Color trackColor;
  final Color accent;
  final Color innerColor;
  final Color innerTrackColor;
  final int tickCount;
  final double sweepAngle;
  final double startAngle;
  final double arcWidth;
  final double innerArcWidth;
  final String needleStyle;
  final bool showInnerRing;
  final bool showRedline;
  final double redlineStart;
  final Color redlineColor;
  final bool showTickLabels;
  final double min;
  final double max;
  final Color tickLabelColor;

  _GaugePainter({
    required this.t,
    required this.innerT,
    required this.color,
    required this.trackColor,
    required this.accent,
    required this.innerColor,
    required this.innerTrackColor,
    required this.tickCount,
    required this.sweepAngle,
    required this.startAngle,
    required this.arcWidth,
    required this.innerArcWidth,
    required this.needleStyle,
    required this.showInnerRing,
    required this.showRedline,
    required this.redlineStart,
    required this.redlineColor,
    required this.showTickLabels,
    required this.min,
    required this.max,
    required this.tickLabelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.max(0.0, (size.shortestSide / 2) - 8);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final start = (startAngle - 90) * math.pi / 180;
    final full = sweepAngle * math.pi / 180;

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

    canvas.drawArc(rect, start, full, false, track);
    canvas.drawArc(rect, start, full * t, false, arc);

    if (showRedline) {
      final redline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = arcWidth
        ..strokeCap = StrokeCap.butt
        ..color = redlineColor.withValues(alpha: 0.8);
      final rStart = start + full * redlineStart;
      final rSweep = full * (1.0 - redlineStart);
      canvas.drawArc(rect, rStart, rSweep, false, redline);
    }

    if (showInnerRing) {
      final innerRadius = radius - arcWidth - 4;
      if (innerRadius > 10) {
        final innerRect = Rect.fromCircle(center: center, radius: innerRadius);
        final innerTrack = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerArcWidth
          ..strokeCap = StrokeCap.round
          ..color = innerTrackColor;
        final innerArc = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = innerArcWidth
          ..strokeCap = StrokeCap.round
          ..color = innerColor;
        canvas.drawArc(innerRect, start, full, false, innerTrack);
        canvas.drawArc(innerRect, start, full * innerT, false, innerArc);
      }
    }

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

        if (showTickLabels) {
          final labelR = radius - 18;
          final lp = center + Offset(math.cos(a) * labelR, math.sin(a) * labelR);
          final v = min + (max - min) * i / tickCount;
          final text = TextPainter(
            text: TextSpan(
              text: v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1),
              style: TextStyle(color: tickLabelColor, fontSize: 9),
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout();
          text.paint(canvas, lp - Offset(text.width / 2, text.height / 2));
        }
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
      old.innerT != innerT ||
      old.color != color ||
      old.accent != accent ||
      old.innerColor != innerColor ||
      old.tickCount != tickCount ||
      old.sweepAngle != sweepAngle ||
      old.startAngle != startAngle ||
      old.arcWidth != arcWidth ||
      old.innerArcWidth != innerArcWidth ||
      old.needleStyle != needleStyle ||
      old.showInnerRing != showInnerRing ||
      old.showRedline != showRedline ||
      old.redlineStart != redlineStart ||
      old.showTickLabels != showTickLabels;
}
