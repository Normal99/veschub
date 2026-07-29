library;

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
  final bool laneLeft;
  final bool laneRight;
  final bool carAhead;

  _CarVizPainter({
    required this.color,
    required this.accent,
    required this.laneLeft,
    required this.laneRight,
    required this.carAhead,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.65;

    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color.withValues(alpha: 0.3);

    canvas.drawLine(Offset(cx - 40, size.height * 0.9), Offset(cx - 20, size.height * 0.2), lanePaint);
    canvas.drawLine(Offset(cx + 40, size.height * 0.9), Offset(cx + 20, size.height * 0.2), lanePaint);

    if (laneLeft) {
      final lp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent;
      canvas.drawLine(Offset(cx - 40, size.height * 0.9), Offset(cx - 20, size.height * 0.2), lp);
    }
    if (laneRight) {
      final rp = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = accent;
      canvas.drawLine(Offset(cx + 40, size.height * 0.9), Offset(cx + 20, size.height * 0.2), rp);
    }

    final carPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final carRect = RRect.fromRectAndCorners(
      Rect.fromCenter(center: Offset(cx, cy), width: 24, height: 40),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
      bottomLeft: const Radius.circular(3),
      bottomRight: const Radius.circular(3),
    );
    canvas.drawRRect(carRect, carPaint);

    if (carAhead) {
      final aheadPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.6);
      final aheadRect = RRect.fromRectAndCorners(
        Rect.fromCenter(center: Offset(cx, cy - 60), width: 20, height: 32),
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );
      canvas.drawRRect(aheadRect, aheadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CarVizPainter old) =>
      old.laneLeft != laneLeft || old.laneRight != laneRight || old.carAhead != carAhead;
}
