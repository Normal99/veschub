/// A simple text/value widget that displays a bound numeric or string value
/// with an optional label and unit.
library;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

/// Renders a `text` widget from resolved properties:
///  * `value`  — the bound value (num or String)
///  * `label`  — optional caption above the value
///  * `unit`   — optional unit suffix
///  * `color`  — optional ARGB int text colour (defaults to accent/white)
class TextWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const TextWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final value = properties['value'];
    final label = properties['label'] as String?;
    final unit = properties['unit'] as String?;
    final color = (properties['color'] as int?) ?? 0xFFFFFFFF;

    final text = _format(value);
    final valueStyle = TextStyle(
      color: Color(color),
      fontSize: 40,
      fontWeight: FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final labelStyle = TextStyle(
      color: Color(color).withValues(alpha: 0.7),
      fontSize: 14,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (label != null) Text(label, style: labelStyle),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(text,
                  style: valueStyle, overflow: TextOverflow.ellipsis),
            ),
            if (unit != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(unit, style: labelStyle),
              ),
          ],
        ),
      ],
    );
  }

  String _format(Object? v) {
    if (v is num) {
      if (v is int || v == v.roundToDouble()) return v.toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }
    return v?.toString() ?? '--';
  }
}
