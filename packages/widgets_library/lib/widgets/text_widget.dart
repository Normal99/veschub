/// A simple text/value widget that displays a bound numeric or string value
/// with an optional label and unit.
library;

import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

import '../src/cosmetic_helpers.dart';

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
    final label = properties['label'] is String ? properties['label'] as String : null;
    final unit = properties['unit'] is String ? properties['unit'] as String : null;
    final color = propInt(properties, 'color', 0xFFFFFFFF);
    final fontSizeRaw = propDouble(properties, 'fontSize', 40.0);

    final text = _format(value);
    final baseStyle = TextStyle(
      color: Color(color),
      fontSize: fontSizeRaw,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final valueStyle = applyTextStyle(
      baseStyle.copyWith(fontWeight: FontWeight.w600),
      properties,
    );
    final labelStyle = applyTextStyle(
      TextStyle(
        color: Color(color).withValues(alpha: 0.7),
        fontSize: (fontSizeRaw.toDouble() * 0.35).clamp(10, 18),
      ),
      properties,
    );

    final content = Padding(
      padding: resolvePadding(properties),
      child: Column(
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
      ),
    );

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: content,
      ),
      properties,
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
