/// A horizontal/vertical bar widget that fills proportionally to a bound
/// value between `min` and `max`.
library;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

import '../src/cosmetic_helpers.dart';

/// Renders a `bar` widget from resolved properties:
///  * `value` — current value (num)
///  * `min`   — scale minimum (num, default 0)
///  * `max`   — scale maximum (num, default 1)
///  * `color` — fill colour (ARGB int, default accent)
///  * `orientation` — 'horizontal' (default) or 'vertical'
///  * `barRadius`      — corner radius of the fill itself (defaults to
///    `borderRadius`, which still controls the track/container)
///  * `showValue`      — overlay the formatted current value as text
///  * `gradient`       — fill with a gradient from `color` to `gradientColor`
///    instead of a flat colour
///  * `gradientColor`  — the gradient's second colour (ARGB int)
class BarWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const BarWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final value = propDouble(properties, 'value', 0.0);
    final min = propDouble(properties, 'min', 0.0);
    final max = propDouble(properties, 'max', 1.0);
    final color = propColor(properties, 'color', 0xFFFFFFFF);
    final vertical = properties['orientation'] == 'vertical';
    final radius = propDouble(properties, 'borderRadius', 6.0);
    final barRadius = propDouble(properties, 'barRadius', radius);
    final showValue = propBool(properties, 'showValue');
    final useGradient = propBool(properties, 'gradient');
    final gradientColor =
        propColor(properties, 'gradientColor', color.toARGB32());

    final span = (max - min) == 0 ? 1.0 : (max - min);
    var t = (value - min) / span;
    t = t.clamp(0.0, 1.0);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackColor = color.withValues(alpha: 0.18);
              // The track always gets a visible outline so the bar's bounds read
              // clearly even at 0% fill or against a similarly dark background —
              // without this it can look like an empty box with nothing in it.
              final trackBorder =
                  Border.all(color: color.withValues(alpha: 0.4));
              final fillDecoration = BoxDecoration(
                color: useGradient ? null : color,
                gradient: useGradient
                    ? LinearGradient(
                        begin: vertical
                            ? Alignment.bottomCenter
                            : Alignment.centerLeft,
                        end: vertical
                            ? Alignment.topCenter
                            : Alignment.centerRight,
                        colors: [color, gradientColor],
                      )
                    : null,
                borderRadius: BorderRadius.circular(barRadius),
              );
              final valueLabel = showValue
                  ? Center(
                      child: Text(
                        value == value.roundToDouble()
                            ? value.toStringAsFixed(0)
                            : value.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    )
                  : null;
              if (vertical) {
                final h = constraints.maxHeight * t;
                return Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: trackColor,
                        border: trackBorder,
                        borderRadius: BorderRadius.circular(radius),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: h.isFinite ? h : 0,
                        width: double.infinity,
                        decoration: fillDecoration,
                      ),
                    ),
                    if (valueLabel != null) valueLabel,
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
                      border: trackBorder,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: w.isFinite ? w : 0,
                      height: double.infinity,
                      decoration: fillDecoration,
                    ),
                  ),
                  if (valueLabel != null) valueLabel,
                ],
              );
            },
          ),
        ),
      ),
      properties,
    );
  }
}
