/// A rolling line chart that plots a bound telemetry value over time.
///
/// Maintains an in-memory ring buffer of recent samples (per widget instance)
/// and renders them as a smoothed polyline with [CustomPainter]. Because each
/// chart instance keeps its own history, only dirty charts repaint (the
/// runtime's per-widget `RepaintBoundary` ensures this).
library;

import 'dart:collection';
import 'dart:math' as math;

import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:flutter/material.dart';

import '../src/cosmetic_helpers.dart';
import '../src/format.dart';
import '../src/theme.dart';

/// Renders a `chart` widget from resolved properties:
///  * `value`   — current value (num); pushed into the history each repaint
///  * `min`     — y-axis minimum (num, default auto)
///  * `max`     — y-axis maximum (num, default auto)
///  * `window`  — sample count to retain (default 120)
///  * `color`   — line colour (ARGB int)
///  * `label`   — optional caption
///  * `unit`    — optional unit suffix on the current readout
class ChartWidget extends StatefulWidget {
  final ResolvedProperties properties;

  const ChartWidget({required this.properties, super.key});

  @override
  State<ChartWidget> createState() => _ChartWidgetState();
}

class _ChartWidgetState extends State<ChartWidget> {
  final Queue<double> _history = Queue();
  int _maxSamples = 120;

  @override
  Widget build(BuildContext context) {
    final theme = DashboardThemeProvider.of(context);
    final value = propDoubleOpt(widget.properties, 'value');
    final min = propDoubleOpt(widget.properties, 'min');
    final max = propDoubleOpt(widget.properties, 'max');
    final color = Color(propInt(widget.properties, 'color', 0xFF4FC3F7));
    final label = widget.properties['label'] as String?;
    final unit = widget.properties['unit'] as String?;
    final window = propInt(widget.properties, 'window', 120);
    final fontSizeRaw = propDouble(widget.properties, 'fontSize', 20.0);
    if (window != _maxSamples) _maxSamples = window;

    // Push the latest sample.
    if (value != null && !value.isNaN && value.isFinite) {
      _history.addLast(value);
      while (_history.length > _maxSamples) {
        _history.removeFirst();
      }
    }

    final samples = _history.toList();
    final yMin = min ?? (samples.isEmpty ? 0 : samples.reduce(math.min));
    final yMax = max ??
        (samples.isEmpty
            ? 1
            : samples.reduce(math.max).toDouble().clamp(1e-9, double.infinity));

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(widget.properties),
        child: Padding(
          padding: resolvePadding(widget.properties),
          child: CustomPaint(
            painter: _ChartPainter(
              samples: samples,
              min: yMin,
              max: yMax,
              color: color,
              gridColor: theme.secondary.withValues(alpha: 0.2),
              lineWidth: (widget.properties['lineWidth'] as num?)?.toDouble() ?? 2,
              showGrid: propBool(widget.properties, 'showGrid', fallback: true),
              smoothCurve: propBool(widget.properties, 'smoothCurve', fallback: true),
              fillArea: propBool(widget.properties, 'fillArea'),
              fillColor: (widget.properties['fillColor'] as int?) ?? 0x224FC3F7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: applyTextStyle(
                      TextStyle(color: theme.secondary, fontSize: (fontSizeRaw.toDouble() * 0.6).clamp(9, 14)),
                      widget.properties,
                    ),
                  ),
                const Spacer(),
                if (value != null)
                  Text(
                    '${formatNumber(value)}${unit != null ? ' $unit' : ''}',
                    style: applyTextStyle(
                      TextStyle(
                        color: color,
                        fontSize: fontSizeRaw.toDouble(),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      widget.properties,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      widget.properties,
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<double> samples;
  final double min;
  final double max;
  final Color color;
  final Color gridColor;
  final double lineWidth;
  final bool showGrid;
  final bool smoothCurve;
  final bool fillArea;
  final int fillColor;

  _ChartPainter({
    required this.samples,
    required this.min,
    required this.max,
    required this.color,
    required this.gridColor,
    required this.lineWidth,
    required this.showGrid,
    required this.smoothCurve,
    required this.fillArea,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final grid = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5
        ..color = gridColor;
      for (var i = 0; i <= 4; i++) {
        final y = size.height * i / 4;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    if (samples.length < 2) return;
    final span = (max - min) == 0 ? 1.0 : (max - min);

    if (fillArea) {
      final fill = Paint()..color = Color(fillColor);
      final fillPath = Path();
      final xStep = size.width / (samples.length - 1);
      fillPath.moveTo(0, size.height);
      for (var i = 0; i < samples.length; i++) {
        final x = i * xStep;
        final t = ((samples[i] - min) / span).clamp(0.0, 1.0);
        final y = size.height * (1 - t);
        fillPath.lineTo(x, y);
      }
      fillPath.lineTo(size.width, size.height);
      fillPath.close();
      canvas.drawPath(fillPath, fill);
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final linePath = Path();
    final xStep = size.width / (samples.length - 1);
    for (var i = 0; i < samples.length; i++) {
      final x = i * xStep;
      final t = ((samples[i] - min) / span).clamp(0.0, 1.0);
      final y = size.height * (1 - t);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else if (smoothCurve && i > 1) {
        final cx = (i - 1) * xStep;
        final cy = size.height *
            (1 - ((samples[i - 1] - min) / span).clamp(0.0, 1.0));
        linePath.quadraticBezierTo(cx, cy, x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }
    canvas.drawPath(linePath, line);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) =>
      old.samples != samples ||
      old.min != min ||
      old.max != max ||
      old.color != color ||
      old.gridColor != gridColor ||
      old.lineWidth != lineWidth ||
      old.showGrid != showGrid ||
      old.smoothCurve != smoothCurve ||
      old.fillArea != fillArea ||
      old.fillColor != fillColor;
}
