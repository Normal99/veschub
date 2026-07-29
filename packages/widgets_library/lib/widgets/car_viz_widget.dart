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
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF4488FF);
    final doorLeft = properties['doorLeft'] as bool? ?? false;
    final doorRight = properties['doorRight'] as bool? ?? false;
    final laneLeft = properties['laneLeft'] as bool? ?? false;
    final laneRight = properties['laneRight'] as bool? ?? false;
    final carAhead = properties['carAhead'] as bool? ?? false;
    final label = properties['label'] as String?;

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
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              if (label != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(label, style: TextStyle(color: accent, fontSize: 11)),
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

  _CarVizPainter({
    required this.color,
    required this.accent,
    required this.doorLeft,
    required this.doorRight,
    required this.laneLeft,
    required this.laneRight,
    required this.carAhead,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.6;
    final carWidth = size.width * 0.35;
    final carHeight = size.height * 0.55;

    // Draw lane lines (converging perspective)
    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.3);

    final laneOffset = carWidth * 3;
    canvas.drawLine(
      Offset(cx - laneOffset, size.height * 0.95),
      Offset(cx - laneOffset * 0.3, size.height * 0.05),
      lanePaint,
    );
    canvas.drawLine(
      Offset(cx + laneOffset, size.height * 0.95),
      Offset(cx + laneOffset * 0.3, size.height * 0.05),
      lanePaint,
    );

    if (laneLeft) {
      final lp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent;
      canvas.drawLine(
        Offset(cx - laneOffset, size.height * 0.95),
        Offset(cx - laneOffset * 0.3, size.height * 0.05),
        lp,
      );
    }
    if (laneRight) {
      final rp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent;
      canvas.drawLine(
        Offset(cx + laneOffset, size.height * 0.95),
        Offset(cx + laneOffset * 0.3, size.height * 0.05),
        rp,
      );
    }

    // Draw car body (top-down view) - Tesla Model 3-like proportions
    final carPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    
    // Main body - rounded rectangle with Tesla-like shape (longer, sleeker)
    final bodyRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, cy), width: carWidth, height: carHeight),
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: const Radius.circular(14),
      bottomRight: const Radius.circular(14),
    );
    canvas.drawRRect(bodyRect, carPaint);

    // Windshield (top section) - darker, larger for Tesla look
    final windshieldPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF080808);
    final windshieldRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(cx, cy - carHeight * 0.37),
        width: carWidth * 0.95,
        height: carHeight * 0.32,
      ),
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );
    canvas.drawRRect(windshieldRect, windshieldPaint);

    // Rear window (bottom section) - darker
    final rearRect = RRect.fromRectAndCorners(
      Rect.fromCenter(
        center: Offset(cx, cy + carHeight * 0.37),
        width: carWidth * 0.95,
        height: carHeight * 0.26,
      ),
      bottomLeft: const Radius.circular(10),
      bottomRight: const Radius.circular(10),
    );
    canvas.drawRRect(rearRect, windshieldPaint);

    // Draw door indicators (orange highlight on sides when open)
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

    // Draw car ahead (smaller, faded version)
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
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
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
      old.carAhead != carAhead;
}
