library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';
import '../src/format.dart'
    show temperatureUnitFromString, temperatureUnitSuffix, convertTemperature;

class MiniGaugeWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const MiniGaugeWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final rawValue = propDouble(properties, 'value', 0.0);
    final rawMin = propDouble(properties, 'min', 0.0);
    final rawMax = propDouble(properties, 'max', 1.0);
    // `displayUnit` is opt-in temperature conversion (this gauge is used for
    // more than just temperature, so unset behaves exactly as before): when
    // set, value/min/max are all converted together from `sourceUnit` so the
    // fill fraction stays correct, and the unit suffix follows displayUnit.
    final displayUnitRaw = properties['displayUnit'] as String?;
    final double value;
    final double min;
    final double max;
    final String? unit;
    if (displayUnitRaw != null) {
      final sourceUnit = temperatureUnitFromString(properties['sourceUnit'] as String?);
      final displayUnit = temperatureUnitFromString(displayUnitRaw);
      value = convertTemperature(rawValue, from: sourceUnit, to: displayUnit);
      min = convertTemperature(rawMin, from: sourceUnit, to: displayUnit);
      max = convertTemperature(rawMax, from: sourceUnit, to: displayUnit);
      unit = temperatureUnitSuffix(displayUnit);
    } else {
      value = rawValue.toDouble();
      min = rawMin.toDouble();
      max = rawMax.toDouble();
      unit = properties['unit'] as String?;
    }
    final color = propColor(properties, 'color', 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final label = properties['label'] as String?;
    final icon = properties['icon'] as String?;
    final fontSizeRaw = propDouble(properties, 'fontSize', 16.0);
    final style = properties['style'] as String? ?? 'arc';

    final span = (max - min) == 0 ? 1.0 : (max - min);
    final t = ((value - min) / span).clamp(0.0, 1.0);

    final isVertical = (properties['orientation'] == 'vertical') ||
        (properties['width'] != null &&
            properties['height'] != null &&
            (properties['height'] as num) > (properties['width'] as num) * 1.5);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: style == 'bar'
              ? (isVertical
                  ? _buildVerticalBar(t, value.toDouble(), color, accent, label, unit, icon, fontSizeRaw.toDouble())
                  : _buildBar(t, value.toDouble(), color, accent, label, unit, icon, fontSizeRaw.toDouble()))
              : _buildArc(t, value.toDouble(), color, accent, label, unit, icon, fontSizeRaw.toDouble()),
        ),
      ),
      properties,
    );
  }

  Widget _buildArc(double t, double value, Color color, Color accent, String? label, String? unit, String? icon, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null || label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) Icon(_iconFor(icon), color: accent, size: fontSize * 0.8),
                if (icon != null && label != null) const SizedBox(width: 4),
                if (label != null) Text(label, style: TextStyle(color: accent, fontSize: fontSize * 0.65)),
              ],
            ),
          ),
        SizedBox(
          width: 60,
          height: 36,
          child: CustomPaint(
            painter: _MiniArcPainter(t: t, color: color, trackColor: color.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _format(value),
              style: applyTextStyle(
                TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
                properties,
              ),
            ),
            if (unit != null)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(unit, style: TextStyle(color: accent, fontSize: fontSize * 0.55)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBar(double t, double value, Color color, Color accent, String? label, String? unit, String? icon, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            if (icon != null) ...[Icon(_iconFor(icon), color: accent, size: fontSize * 0.8), const SizedBox(width: 4)],
            if (label != null) Expanded(child: Text(label, style: TextStyle(color: accent, fontSize: fontSize * 0.65))),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(_format(value), style: applyTextStyle(TextStyle(color: color, fontSize: fontSize, fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]), properties)),
                if (unit != null) Padding(padding: const EdgeInsets.only(left: 2), child: Text(unit, style: TextStyle(color: accent, fontSize: fontSize * 0.55))),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: t,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalBar(double t, double value, Color color, Color accent, String? label, String? unit, String? icon, double fontSize) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null || label != null)
          Column(
            children: [
              if (icon != null) Icon(_iconFor(icon), color: accent, size: fontSize * 0.9),
              if (label != null) Text(label, style: TextStyle(color: accent, fontSize: fontSize * 0.65, fontWeight: FontWeight.bold)),
            ],
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: RotatedBox(
              quarterTurns: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: t,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                  minHeight: 12,
                ),
              ),
            ),
          ),
        ),
        Text(
          unit != null ? '$unit ${_format(value)}' : _format(value),
          style: TextStyle(color: color, fontSize: fontSize * 0.75, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  IconData? _iconFor(String name) => switch (name) {
        'battery' => Icons.battery_full,
        'temp' || 'temperature' => Icons.thermostat,
        'fuel' => Icons.local_gas_station,
        'speed' => Icons.speed,
        'power' => Icons.bolt,
        _ => null,
      };

  String _format(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

class _MiniArcPainter extends CustomPainter {
  final double t;
  final Color color;
  final Color trackColor;

  _MiniArcPainter({required this.t, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = math.min(size.width / 2, size.height) - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color;

    const start = math.pi;
    const sweep = math.pi;
    canvas.drawArc(rect, start, sweep, false, track);
    canvas.drawArc(rect, start, sweep * t, false, arc);
  }

  @override
  bool shouldRepaint(covariant _MiniArcPainter old) => old.t != t || old.color != color;
}
