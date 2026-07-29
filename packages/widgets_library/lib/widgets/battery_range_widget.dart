library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class BatteryRangeWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const BatteryRangeWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final batteryLevel = (properties['batteryLevel'] as num?)?.toDouble() ?? 0.0;
    final range = (properties['range'] as num?)?.toDouble() ?? 0;
    final temperature = (properties['temperature'] as num?)?.toDouble();
    final color = Color((properties['color'] as int?) ?? 0xFF00FF00);
    final textColor = Color((properties['textColor'] as int?) ?? 0xFFFFFFFF);
    final accentColor = Color((properties['accentColor'] as int?) ?? 0xFF888888);
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 16.0;
    final showRange = properties['showRange'] as bool? ?? true;
    final showTemperature = properties['showTemperature'] as bool? ?? true;
    final unit = properties['unit'] as String? ?? 'km';
    final tempUnit = properties['tempUnit'] as String? ?? '°C';

    final barWidth = 360.0;
    final barHeight = 56.0;
    final filledWidth = barWidth * batteryLevel.clamp(0.0, 1.0);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: barWidth,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: filledWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (showRange) ...[
                const SizedBox(width: 32),
                Text(
                  '${range.round()} $unit',
                  style: TextStyle(
                    color: textColor,
                    fontSize: fontSizeRaw.toDouble(),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (showTemperature && temperature != null) ...[
                const SizedBox(width: 36),
                Text(
                  '${temperature.round()}$tempUnit',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: fontSizeRaw.toDouble(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      properties,
    );
  }
}
