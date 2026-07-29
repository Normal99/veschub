library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class ClimateWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const ClimateWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final temperature = (properties['temperature'] as num?)?.toDouble() ?? 22;
    final targetTemp = (properties['targetTemp'] as num?)?.toDouble();
    final fanSpeed = (properties['fanSpeed'] as num?)?.toDouble();
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 32.0;
    final unit = properties['unit'] as String? ?? '°C';
    final mode = properties['mode'] as String?;

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (mode != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_modeIcon(mode), color: accent, size: fontSizeRaw * 0.45),
                    const SizedBox(width: 4),
                    Text(mode, style: TextStyle(color: accent, fontSize: fontSizeRaw * 0.4)),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _format(temperature),
                    style: applyTextStyle(
                      TextStyle(
                        color: color,
                        fontSize: fontSizeRaw.toDouble(),
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      properties,
                    ),
                  ),
                  Text(unit, style: TextStyle(color: accent, fontSize: fontSizeRaw * 0.4)),
                ],
              ),
              if (targetTemp != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Target: ${_format(targetTemp)}$unit',
                    style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: fontSizeRaw * 0.35),
                  ),
                ),
              if (fanSpeed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.air, color: accent, size: fontSizeRaw * 0.4),
                      const SizedBox(width: 4),
                      Text(
                        'Fan ${(fanSpeed * 100).round()}%',
                        style: TextStyle(color: accent.withValues(alpha: 0.7), fontSize: fontSizeRaw * 0.35),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      properties,
    );
  }

  IconData _modeIcon(String mode) => switch (mode) {
        'cool' || 'Cooling' => Icons.ac_unit,
        'heat' || 'Heating' => Icons.local_fire_department,
        'auto' || 'Auto' => Icons.thermostat_auto,
        'defrost' => Icons.wind_power,
        _ => Icons.thermostat,
      };

  String _format(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
