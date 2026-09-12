library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class CarVizWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const CarVizWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final colorVal = properties['color'];
    final color = Color(colorVal is int ? colorVal : 0xFFFFFFFF);
    final accentVal = properties['accent'];
    final accent = Color(accentVal is int ? accentVal : 0xFF4488FF);
    final doorLeft = properties['doorLeft'] == true;
    final doorRight = properties['doorRight'] == true;
    final laneLeft = properties['laneLeft'] == true;
    final laneRight = properties['laneRight'] == true;
    final carAhead = properties['carAhead'] == true;
    final showRing = properties['showRing'] == true;
    final showLabels = properties['showLabels'] == true;
    final label = properties['label']?.toString();
    final fontSizeVal = properties['fontSize'];
    final fontSize = (fontSizeVal is num ? fontSizeVal.toDouble() : null) ?? 14.0;

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _CarVizPainter(
                    color: color,
                    accent: accent,
                    doorLeft: doorLeft,
                    doorRight: doorRight,
                    laneLeft: laneLeft,
                    laneRight: laneRight,
                    carAhead: carAhead,
                    showRing: showRing,
                    showLabels: showLabels,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: applyTextStyle(
                        TextStyle(
                          color: accent,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                        ),
                        properties,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      properties,
    );
  }
}

class _CarVizPainter extends CustomPainter {
  final Color color;
  final Color accent;
  final bool doorLeft;
  final bool doorRight;
  final bool laneLeft;
  final bool laneRight;
  final bool carAhead;
  final bool showRing;
  final bool showLabels;

  _CarVizPainter({
    required this.color,
    required this.accent,
    required this.doorLeft,
    required this.doorRight,
    required this.laneLeft,
    required this.laneRight,
    required this.carAhead,
    required this.showRing,
    required this.showLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.5;
    final carWidth = size.width * 0.38;
    final carHeight = size.height * 0.65;

    if (showRing) {
      final center = Offset(cx, cy);
      final radius = (math.min(size.width, size.height) / 2) - 4;

      final outerRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF6B6699).withValues(alpha: 0.6);

      final innerRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF9995C8).withValues(alpha: 0.4);

      canvas.drawCircle(center, radius, outerRing);
      canvas.drawCircle(center, radius - 8, innerRing);

      if (showLabels) {
        final textPainterFront = TextPainter(
          text: const TextSpan(
            text: 'Front',
            style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainterFront.paint(canvas, Offset(cx + carWidth * 0.65, cy - carHeight * 0.25));

        final textPainterRear = TextPainter(
          text: const TextSpan(
            text: 'Rear',
            style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 16, fontWeight: FontWeight.w500),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainterRear.paint(canvas, Offset(cx + carWidth * 0.65, cy + carHeight * 0.25));
      }
    }

    // Draw lane lines
    if (!showRing) {
      final lanePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withValues(alpha: 0.2);

      final laneOffset = carWidth * 1.5;
      canvas.drawLine(
        Offset(cx - laneOffset, size.height * 0.85),
        Offset(cx - laneOffset * 0.75, size.height * 0.15),
        lanePaint,
      );
      canvas.drawLine(
        Offset(cx + laneOffset, size.height * 0.85),
        Offset(cx + laneOffset * 0.75, size.height * 0.15),
        lanePaint,
      );
    }

    if (laneLeft) {
      final lp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = accent;
      canvas.drawLine(
        Offset(cx - carWidth * 1.5, size.height * 0.85),
        Offset(cx - carWidth * 1.1, size.height * 0.15),
        lp,
      );
    }
    if (laneRight) {
      final rp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = accent;
      canvas.drawLine(
        Offset(cx + carWidth * 1.5, size.height * 0.85),
        Offset(cx + carWidth * 1.1, size.height * 0.15),
        rp,
      );
    }

    // Draw car body (top-down view)
    final carPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, cy), width: carWidth, height: carHeight),
      topLeft: const Radius.circular(36),
      topRight: const Radius.circular(36),
      bottomLeft: const Radius.circular(28),
      bottomRight: const Radius.circular(28),
    );
    canvas.drawRRect(bodyRect, carPaint);

    final windshieldPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF111111);
    final windshieldRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(cx, cy - carHeight * 0.15),
        width: carWidth * 0.82,
        height: carHeight * 0.4,
      ),
      topLeft: const Radius.circular(22),
      topRight: const Radius.circular(22),
    );
    canvas.drawRRect(windshieldRect, windshieldPaint);

    final rearRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(cx, cy + carHeight * 0.32),
        width: carWidth * 0.82,
        height: carHeight * 0.28,
      ),
      bottomLeft: const Radius.circular(20),
      bottomRight: const Radius.circular(20),
    );
    canvas.drawRRect(rearRect, windshieldPaint);

    if (doorLeft) {
      final doorPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF9800);
      final doorRect = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(cx - carWidth * 0.55, cy),
          width: carWidth * 0.1,
          height: carHeight * 0.7,
        ),
        topLeft: const Radius.circular(3),
        bottomLeft: const Radius.circular(3),
      );
      canvas.drawRRect(doorRect, doorPaint);
    }

    if (doorRight) {
      final doorPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFF9800);
      final doorRect = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(cx + carWidth * 0.55, cy),
          width: carWidth * 0.1,
          height: carHeight * 0.7,
        ),
        topRight: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );
      canvas.drawRRect(doorRect, doorPaint);
    }

    if (carAhead) {
      final aheadPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.4);
      final aheadRect = RRect.fromRectAndCorners(
        Rect.fromCenter(
          center: Offset(cx, cy - carHeight * 1.8),
          width: carWidth * 0.7,
          height: carHeight * 0.9,
        ),
        topLeft: const Radius.circular(26),
        topRight: const Radius.circular(26),
        bottomLeft: const Radius.circular(22),
        bottomRight: const Radius.circular(22),
      );
      canvas.drawRRect(aheadRect, aheadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CarVizPainter old) =>
      old.doorLeft != doorLeft ||
      old.doorRight != doorRight ||
      old.laneLeft != laneLeft ||
      old.laneRight != laneRight ||
      old.carAhead != carAhead ||
      old.showRing != showRing ||
      old.showLabels != showLabels;
}
