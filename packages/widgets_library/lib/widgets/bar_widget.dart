/// A horizontal/vertical bar widget that fills proportionally to a bound
/// value between `min` and `max`.
library;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

/// Renders a `bar` widget from resolved properties:
///  * `value` — current value (num)
///  * `min`   — scale minimum (num, default 0)
///  * `max`   — scale maximum (num, default 1)
///  * `color` — fill colour (ARGB int, default accent)
///  * `orientation` — 'horizontal' (default) or 'vertical'
class BarWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const BarWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final value = (properties['value'] as num?)?.toDouble() ?? 0;
    final min = (properties['min'] as num?)?.toDouble() ?? 0;
    final max = (properties['max'] as num?)?.toDouble() ?? 1;
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final vertical = properties['orientation'] == 'vertical';

    final span = (max - min) == 0 ? 1.0 : (max - min);
    var t = (value - min) / span;
    t = t.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackColor = color.withValues(alpha: 0.18);
        if (vertical) {
          final h = constraints.maxHeight * t;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: h.isFinite ? h : 0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          );
        }
        final w = constraints.maxWidth * t;
        return Stack(
          children: [
            Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: w.isFinite ? w : 0,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
