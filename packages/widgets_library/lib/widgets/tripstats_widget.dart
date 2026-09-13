library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class TripStatsWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const TripStatsWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final color = propColor(properties, 'color', 0xFFFFFFFF);
    final accent = propColor(properties, 'accent', 0xFF888888);
    final layoutStyle = properties['layoutStyle'] is String
        ? properties['layoutStyle'] as String
        : 'standard';

    if (layoutStyle == 'tesla_grid' || layoutStyle == '3x3') {
      return _buildTeslaGrid(context, color, accent);
    }

    if (layoutStyle == 'porsche') {
      return _buildPorschePod(context, color, accent);
    }

    final label1 = (properties['label1'] is String
            ? properties['label1'] as String
            : null) ??
        'Distance';
    final value1 = properties['value1'];
    final unit1 = (properties['unit1'] is String
            ? properties['unit1'] as String
            : null) ??
        'km';
    final label2 = (properties['label2'] is String
            ? properties['label2'] as String
            : null) ??
        'Time';
    final value2 = properties['value2'];
    final unit2 = (properties['unit2'] is String
            ? properties['unit2'] as String
            : null) ??
        'min';
    final label3 = (properties['label3'] is String
            ? properties['label3'] as String
            : null) ??
        'Avg Speed';
    final value3 = properties['value3'];
    final unit3 = (properties['unit3'] is String
            ? properties['unit3'] as String
            : null) ??
        'km/h';
    final label4 = (properties['label4'] is String
            ? properties['label4'] as String
            : null) ??
        'Energy';
    final value4 = properties['value4'];
    final unit4 = (properties['unit4'] is String
            ? properties['unit4'] as String
            : null) ??
        'Wh';
    final columns = propInt(properties, 'columns', 2).clamp(1, 6);
    final fontSizeRaw = propDouble(properties, 'fontSize', 20.0);

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
              final rows = (items.length / columns).ceil();
              final itemHeight = rows > 0
                  ? (constraints.maxHeight / rows)
                  : constraints.maxHeight;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map((item) => SizedBox(
                          width: ((constraints.maxWidth - 8) / columns)
                              .clamp(1.0, double.infinity),
                          height: (itemHeight - 8).clamp(1.0, double.infinity),
                          child: _StatTile(
                            label: item.label,
                            value: _format(item.value),
                            unit: item.unit,
                            color: color,
                            accent: accent,
                            fontSize: fontSizeRaw.toDouble(),
                            properties: properties,
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ),
      ),
      properties,
    );
  }

  Widget _buildPorschePod(BuildContext context, Color color, Color accent) {
    final header = properties['section1Header'] as String? ?? 'Since 2:03 PM';
    final l1 = properties['label1'] as String? ?? 'Time';
    final v1 = _format(properties['value1']);
    final u1 = properties['unit1'] as String? ?? 'min';

    final l2 = properties['label2'] as String? ?? 'Dist.';
    final v2 = _format(properties['value2']);
    final u2 = properties['unit2'] as String? ?? 'mi';

    final l3 = properties['label3'] as String? ?? 'Consum.';
    final v3 = _format(properties['value3']);
    final u3 = properties['unit3'] as String? ?? 'kWh/100mi';

    final l4 = properties['label4'] as String? ?? 'Speed';
    final v4 = _format(properties['value4']);
    final u4 = properties['unit4'] as String? ?? 'mph';

    return applyOpacity(
      CustomPaint(
        painter: _PorschePodRingPainter(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 70, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                header,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),
              _buildRow(l1, '$v1 $u1', color, accent),
              const SizedBox(height: 12),
              _buildRow(l2, '$v2 $u2', color, accent),
              const SizedBox(height: 12),
              _buildRow(l3, '$v3 $u3', color, accent),
              const SizedBox(height: 12),
              _buildRow(l4, '$v4 $u4', color, accent),
            ],
          ),
        ),
      ),
      properties,
    );
  }

  Widget _buildRow(String label, String valueStr, Color color, Color accent) {
    // Both sides are Flexible with ellipsis rather than fixed-size Text:
    // this row's fixed fontSizes (18/20) can overflow a narrower pod width
    // than the "Since 2:03 PM" header was designed around — found by a
    // golden-regression test (51px horizontal overflow on the stock
    // porsche_taycan.veschub.json example).
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
                color: accent.withValues(alpha: 0.85),
                fontSize: 18,
                fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: Text(
            valueStr,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTeslaGrid(BuildContext context, Color color, Color accent) {
    final s1Header = properties['section1Header'] as String? ?? 'Since 10:49';
    final s1V1 = _format(properties['section1Val1']);
    final s1U1 = properties['unit1_1'] as String? ?? 'km';
    final s1V2 = _format(properties['section1Val2']);
    final s1U2 = properties['unit1_2'] as String? ?? 'min';
    final s1V3 = _format(properties['section1Val3']);
    final s1U3 = properties['unit1_3'] as String? ?? 'Wh/km';

    final s2Header =
        properties['section2Header'] as String? ?? 'Since last charge';
    final s2V1 = _format(properties['section2Val1']);
    final s2U1 = properties['unit2_1'] as String? ?? 'km';
    final s2V2 = _format(properties['section2Val2']);
    final s2U2 = properties['unit2_2'] as String? ?? 'kWh';
    final s2V3 = _format(properties['section2Val3']);
    final s2U3 = properties['unit2_3'] as String? ?? 'Wh/km';

    final s3Header = properties['section3Header'] as String? ?? 'Monthly';
    final s3V1 = _format(properties['section3Val1']);
    final s3U1 = properties['unit3_1'] as String? ?? 'km';
    final s3V2 = _format(properties['section3Val2']);
    final s3U2 = properties['unit3_2'] as String? ?? 'kWh';
    final s3V3 = _format(properties['section3Val3']);
    final s3U3 = properties['unit3_3'] as String? ?? 'Wh/km';

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSection(
                  s1Header, s1V1, s1U1, s1V2, s1U2, s1V3, s1U3, color, accent),
              _buildSection(
                  s2Header, s2V1, s2U1, s2V2, s2U2, s2V3, s2U3, color, accent),
              _buildSection(
                  s3Header, s3V1, s3U1, s3V2, s3U2, s3V3, s3U3, color, accent),
            ],
          ),
        ),
      ),
      properties,
    );
  }

  Widget _buildSection(
    String header,
    String v1,
    String u1,
    String v2,
    String u2,
    String v3,
    String u3,
    Color color,
    Color accent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
                child: Container(
                    height: 1, color: accent.withValues(alpha: 0.25))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                header,
                style: TextStyle(
                    color: accent.withValues(alpha: 0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
                child: Container(
                    height: 1, color: accent.withValues(alpha: 0.25))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildColumnCell(v1, u1, color, accent)),
            Expanded(child: _buildColumnCell(v2, u2, color, accent)),
            Expanded(child: _buildColumnCell(v3, u3, color, accent)),
          ],
        ),
      ],
    );
  }

  Widget _buildColumnCell(String val, String unit, Color color, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
              color: accent.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500),
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

class _PorschePodRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - 4;

    final outerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF6B6699).withValues(alpha: 0.6);

    final innerRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF9995C8).withValues(alpha: 0.4);

    canvas.drawCircle(center, radius, outerRing);
    canvas.drawCircle(center, radius - 8, innerRing);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(color: accent, fontSize: fontSize * 0.5)),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: applyTextStyle(
                  TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  properties,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (unit != null && unit!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    unit!,
                    style: TextStyle(
                      color: accent,
                      fontSize: fontSize * 0.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
