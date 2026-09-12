library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class BatteryRangeWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const BatteryRangeWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final batteryLevel = propDouble(properties, 'batteryLevel', 0.0);
    final range = propDouble(properties, 'range', 0.0);
    final temperature = propDoubleOpt(properties, 'temperature');
    final color = propColor(properties, 'color', 0xFF00FF00);
    final textColor = propColor(properties, 'textColor', 0xFFFFFFFF);
    final accentColor = propColor(properties, 'accentColor', 0xFF888888);
    final fontSizeRaw = propDouble(properties, 'fontSize', 16.0);
    final showRange = propBool(properties, 'showRange', fallback: true);
    final showTemperature = propBool(properties, 'showTemperature', fallback: true);
    final unit = properties['unit'] is String ? properties['unit'] as String : 'km';
    final tempUnit = properties['tempUnit'] is String ? properties['tempUnit'] as String : '°C';

    final barWidth = 360.0;
    final barHeight = 56.0;
    final filledWidth = barWidth * batteryLevel.clamp(0.0, 1.0);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availW = constraints.maxWidth.isFinite ? constraints.maxWidth : 400.0;
              final barH = (constraints.maxHeight.isFinite ? constraints.maxHeight - 16 : 48.0).clamp(20.0, 56.0);
              final barW = (showRange ? (availW * 0.45) : availW * 0.85).clamp(80.0, 360.0);
              final filledW = barW * batteryLevel.clamp(0.0, 1.0);

              final textStyle = applyTextStyle(
                TextStyle(
                  color: textColor,
                  fontSize: fontSizeRaw,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                properties,
              );

              final tempStyle = applyTextStyle(
                TextStyle(
                  color: accentColor,
                  fontSize: fontSizeRaw,
                  fontWeight: FontWeight.w500,
                ),
                properties,
              );

              return FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: barW,
                      height: barH,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(barH * 0.25),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: filledW,
                          height: barH,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(barH * 0.25),
                          ),
                        ),
                      ),
                    ),
                    if (showRange) ...[
                      const SizedBox(width: 16),
                      Text('${range.round()} $unit', style: textStyle),
                    ],
                    if (showTemperature && temperature != null) ...[
                      const SizedBox(width: 16),
                      Text('${temperature.round()}$tempUnit', style: tempStyle),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
      properties,
    );
  }
}
