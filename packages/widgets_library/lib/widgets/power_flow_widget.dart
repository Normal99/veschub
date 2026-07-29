library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class PowerFlowWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const PowerFlowWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final power = (properties['power'] as num?)?.toDouble() ?? 0;
    final maxPower = (properties['maxPower'] as num?)?.toDouble() ?? 100;
    final color = Color((properties['color'] as int?) ?? 0xFFFF9800);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final label = properties['label'] as String? ?? 'kW';
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 14.0;
    final barWidth = (properties['barWidth'] as num?)?.toDouble() ?? 60.0;
    final barHeight = (properties['barHeight'] as num?)?.toDouble() ?? 4.0;

    final t = (power / maxPower).clamp(0.0, 1.0);
    final isRegen = power < 0;
    final displayPower = power.abs();

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: fontSizeRaw.toDouble() * 0.8,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: isRegen ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: barWidth * t,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _format(displayPower),
                style: TextStyle(
                  color: color,
                  fontSize: fontSizeRaw.toDouble(),
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
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
