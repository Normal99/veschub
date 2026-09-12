library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class DigitalSpeedWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const DigitalSpeedWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final value = (properties['value'] as num?)?.toDouble() ?? 0;
    final unit = properties['unit'] as String? ?? 'km/h';
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 72.0;
    final showUnit = properties['showUnit'] as bool? ?? true;
    final subLabel = properties['subLabel'] as String?;
    final subValue = properties['subValue'];

    final text = _format(value);
    final valueStyle = applyTextStyle(
      TextStyle(
        color: color,
        fontSize: fontSizeRaw.toDouble(),
        fontWeight: FontWeight.w200,
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: -2,
      ),
      properties,
    );
    final unitStyle = applyTextStyle(
      TextStyle(
        color: accent,
        fontSize: (fontSizeRaw.toDouble() * 0.22).clamp(10, 20),
        fontWeight: FontWeight.w400,
      ),
      properties,
    );

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(text, style: valueStyle),
                  if (showUnit)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(unit, style: unitStyle),
                    ),
                ],
              ),
              if (subLabel != null || subValue != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [subLabel, _formatSub(subValue)].whereType<String>().join(' · '),
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.7),
                      fontSize: (fontSizeRaw.toDouble() * 0.16).clamp(9, 14),
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

  String _format(num v) {
    if (v is int || v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String? _formatSub(Object? v) {
    if (v == null) return null;
    if (v is num) {
      if (v is int || v == v.roundToDouble()) return v.toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }
    return v.toString();
  }
}
