library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class PowerFlowWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const PowerFlowWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final powerVal = properties['power'];
    final power = (powerVal is num ? powerVal.toDouble() : null) ?? 0.0;
    final maxPowerVal = properties['maxPower'];
    final maxPower =
        (maxPowerVal is num ? maxPowerVal.toDouble() : null) ?? 100.0;
    final colorVal = properties['color'];
    final color = Color(colorVal is int ? colorVal : 0xFFFF9800);
    final accentVal = properties['accent'];
    final accent = Color(accentVal is int ? accentVal : 0xFF888888);
    final label = properties['label']?.toString() ?? 'kW';
    final fontSizeVal = properties['fontSize'];
    final fontSize =
        (fontSizeVal is num ? fontSizeVal.toDouble() : null) ?? 14.0;
    final barWidthVal = properties['barWidth'];
    final barWidth =
        (barWidthVal is num ? barWidthVal.toDouble() : null) ?? 60.0;
    final barHeightVal = properties['barHeight'];
    final barHeight =
        (barHeightVal is num ? barHeightVal.toDouble() : null) ?? 8.0;

    final t = maxPower == 0 ? 0.0 : (power / maxPower).clamp(0.0, 1.0);
    final isRegen = power < 0;
    final displayPower = power.abs();

    return applyOpacity(
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          decoration: resolveBoxDecoration(properties),
          child: Padding(
            padding: resolvePadding(properties),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isRegen ? Icons.battery_charging_full : Icons.bolt,
                  color: color,
                  size: fontSize * 1.2,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: accent,
                    fontSize: fontSize * 0.8,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    // The track always gets a visible outline so its bounds
                    // read clearly at 0% fill or against a similarly dark
                    // background, same fix as bar_widget.dart's track.
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(barHeight / 2),
                  ),
                  child: Align(
                    alignment:
                        isRegen ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: barWidth * t,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(barHeight / 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _format(displayPower),
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
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
