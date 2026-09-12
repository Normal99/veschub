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
    final value = propDouble(properties, 'value', 0.0);
    final min = propDouble(properties, 'min', 0.0);
    final max = propDouble(properties, 'max', 1.0);
    final color = propColor(properties, 'color', 0xFFFFFFFF);
    final accent = propColor(properties, 'accent', 0xFFFFFFFF);
    final label = properties['label'] is String ? properties['label'] as String : null;
    final unit = properties['unit'] is String ? properties['unit'] as String : null;
    final fontSizeRaw = propDouble(properties, 'fontSize', 32.0);

    final centerValue = propDouble(properties, 'centerValue', value);
    final centerUnit = (properties['centerUnit'] is String ? properties['centerUnit'] as String : null) ?? unit;
    final subLabel = properties['subLabel'] is String ? properties['subLabel'] as String : null;
    final showCenterText = propBool(properties, 'showCenterText');
    final showTickLabels = propBool(properties, 'showTickLabels');

    final innerValue = propDoubleOpt(properties, 'innerValue');
    final innerMin = propDouble(properties, 'innerMin', 0.0);
    final innerMax = propDouble(properties, 'innerMax', 1.0);
    final innerColor = propColor(properties, 'innerColor', 0xFF888888);
    final innerArcWidth = propDouble(properties, 'innerArcWidth', 4.0);
    final showInnerRing = innerValue != null;

    final redlineStart = propDoubleOpt(properties, 'redlineStart');
    final redlineColor = propColor(properties, 'redlineColor', 0xFFFF0000);
    final showRedline = redlineStart != null;

    final span = (max - min) == 0 ? 1.0 : (max - min);
    final t = ((value - min) / span).clamp(0.0, 1.0);
    final innerT = showInnerRing
        ? (((innerValue - innerMin) /
                ((innerMax - innerMin) == 0 ? 1.0 : (innerMax - innerMin)))
            .clamp(0.0, 1.0))
        : 0.0;

    final sweepAngle = (properties['sweepAngle'] as num?)?.toDouble() ?? 270;
    final startAngle = (properties['startAngle'] as num?)?.toDouble() ?? 135;
    final arcWidth = (properties['arcWidth'] as num?)?.toDouble() ?? 10;
    final needleStyle = properties['needleStyle'] as String? ?? 'needle';
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
              fontFamily: properties['fontFamily'] as String?,
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
                              fontWeight: FontWeight.w500,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            properties,
                          ),
                        ),
                        if (centerUnit != null || subLabel != null)
                          Text(
                            [centerUnit, subLabel]
                                .whereType<String>()
                                .join(' '),
                            style: TextStyle(
                              color: accent.withValues(alpha: 0.7),
                              fontSize:
                                  math.max(16.0, fontSizeRaw.toDouble() * 0.15),
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
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
                                fontSize: (fontSizeRaw.toDouble() * 0.38)
                                    .clamp(9, 14),
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
  final String? fontFamily;

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
    this.fontFamily,
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
        final outer =
            center + Offset(math.cos(a) * radius, math.sin(a) * radius);
        final inner = center +
            Offset(math.cos(a) * (radius - 8), math.sin(a) * (radius - 8));
        canvas.drawLine(inner, outer, tick);

        if (showTickLabels) {
          final labelR = radius - 18;
          final lp =
              center + Offset(math.cos(a) * labelR, math.sin(a) * labelR);
          final v = min + (max - min) * i / tickCount;
          final text = TextPainter(
            text: TextSpan(
              text: v == v.roundToDouble()
                  ? v.toStringAsFixed(0)
                  : v.toStringAsFixed(1),
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
      final tip = center +
          Offset(math.cos(a) * (radius - 16), math.sin(a) * (radius - 16));
      final needle = Paint()
        ..style = PaintingStyle.fill
        ..color = color;
      final perpAngle = a + math.pi / 2;
      final base1 =
          center + Offset(math.cos(perpAngle) * 5, math.sin(perpAngle) * 5);
      final base2 =
          center - Offset(math.cos(perpAngle) * 5, math.sin(perpAngle) * 5);
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(base1.dx, base1.dy)
        ..lineTo(base2.dx, base2.dy)
        ..close();
      canvas.drawPath(path, needle);
      canvas.drawCircle(center, 10, Paint()..color = const Color(0xFF1E1E1E));
      canvas.drawCircle(center, 5, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => true;
}
