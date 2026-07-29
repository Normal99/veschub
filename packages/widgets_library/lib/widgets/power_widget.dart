library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class PowerWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const PowerWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final power = (properties['power'] as num?)?.toDouble() ?? 0;
    final maxPower = (properties['maxPower'] as num?)?.toDouble() ?? 100;
    final color = Color((properties['color'] as int?) ?? 0xFF00FF88);
    final regenColor = Color((properties['regenColor'] as int?) ?? 0xFF4488FF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final showBars = properties['showBars'] as bool? ?? true;
    final label = properties['label'] as String? ?? 'Power';
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 28.0;

    final isRegen = power < 0;

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: TextStyle(color: accent, fontSize: fontSizeRaw * 0.4)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _format(power),
                    style: applyTextStyle(
                      TextStyle(
                        color: isRegen ? regenColor : color,
                        fontSize: fontSizeRaw.toDouble(),
                        fontWeight: FontWeight.w300,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      properties,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('W', style: TextStyle(color: accent, fontSize: fontSizeRaw * 0.45)),
                ],
              ),
              if (showBars) ...[
                const SizedBox(height: 8),
                LayoutBuilder(builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final barH = 6.0;
                  final gap = 2.0;
                  final totalBars = 20;
                  final barW = (w - gap * (totalBars - 1)) / totalBars;
                  final activePower = power.abs() / maxPower;
                  final activeBars = (activePower * totalBars).round();
                  return SizedBox(
                    height: barH * 2 + gap,
                    child: Stack(
                      children: [
                        Row(
                          children: List.generate(totalBars, (i) {
                            final isPowerBar = i < totalBars ~/ 2;
                            final idx = isPowerBar
                                ? (totalBars ~/ 2 - 1 - i)
                                : (i - totalBars ~/ 2);
                            final active = idx < activeBars;
                            final c = isPowerBar ? color : regenColor;
                            return Container(
                              width: barW,
                              height: barH,
                              margin: EdgeInsets.only(right: gap),
                              decoration: BoxDecoration(
                                color: active ? c : c.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('REGEN', style: TextStyle(color: regenColor.withValues(alpha: 0.7), fontSize: 9)),
                    Text('POWER', style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 9)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      properties,
    );
  }

  String _format(double v) {
    if (v.abs() >= 1000) return (v / 1000).toStringAsFixed(1);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
