library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class TripStatsWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const TripStatsWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final label1 = properties['label1'] as String? ?? 'Distance';
    final value1 = properties['value1'];
    final unit1 = properties['unit1'] as String? ?? 'km';
    final label2 = properties['label2'] as String? ?? 'Time';
    final value2 = properties['value2'];
    final unit2 = properties['unit2'] as String? ?? 'min';
    final label3 = properties['label3'] as String? ?? 'Avg Speed';
    final value3 = properties['value3'];
    final unit3 = properties['unit3'] as String? ?? 'km/h';
    final label4 = properties['label4'] as String? ?? 'Energy';
    final value4 = properties['value4'];
    final unit4 = properties['unit4'] as String? ?? 'Wh';
    final columns = (properties['columns'] as num?)?.toInt() ?? 2;
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 20.0;

    final items = <_StatItem>[];
    if (label1.isNotEmpty) items.add(_StatItem(label1, value1, unit1));
    if (label2.isNotEmpty) items.add(_StatItem(label2, value2, unit2));
    if (label3.isNotEmpty) items.add(_StatItem(label3, value3, unit3));
    if (label4.isNotEmpty) items.add(_StatItem(label4, value4, unit4));

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemHeight = constraints.maxHeight / ((items.length / columns).ceil());
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => SizedBox(
                  width: (constraints.maxWidth - 8) / columns,
                  height: itemHeight - 8,
                  child: _StatTile(
                    label: item.label,
                    value: _format(item.value),
                    unit: item.unit,
                    color: color,
                    accent: accent,
                    fontSize: fontSizeRaw.toDouble(),
                    properties: properties,
                  ),
                )).toList(),
              );
            },
          ),
        ),
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

class _StatItem {
  final String label;
  final Object? value;
  final String? unit;
  _StatItem(this.label, this.value, this.unit);
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color color;
  final Color accent;
  final double fontSize;
  final ResolvedProperties properties;

  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.accent,
    required this.fontSize,
    required this.properties,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: TextStyle(color: accent, fontSize: fontSize * 0.5)),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: applyTextStyle(
                  TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  properties,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unit != null)
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Text(unit!, style: TextStyle(color: accent, fontSize: fontSize * 0.5)),
              ),
          ],
        ),
      ],
    );
  }
}
