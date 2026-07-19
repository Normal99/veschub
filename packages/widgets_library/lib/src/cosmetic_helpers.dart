import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

BoxDecoration resolveBoxDecoration(ResolvedProperties props) {
  final bgColor = Color((props['backgroundColor'] as int?) ?? 0xFF111111);
  final borderRadiusRaw = (props['borderRadius'] as num?) ?? 0.0;
  final borderWidth = (props['borderWidth'] as num?)?.toDouble() ?? 0.0;
  final borderColor = Color((props['borderColor'] as int?) ?? 0xFFFFFFFF);
  final shadowColor = Color((props['shadowColor'] as int?) ?? 0x00000000);
  final shadowBlur = (props['shadowBlur'] as num?)?.toDouble() ?? 0.0;
  final shadowOffsetY = (props['shadowOffsetY'] as num?)?.toDouble() ?? 2.0;

  return BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(borderRadiusRaw.toDouble()),
    border: borderWidth > 0
        ? Border.all(color: borderColor, width: borderWidth)
        : null,
    boxShadow: shadowBlur > 0 && shadowColor.toARGB32() != 0x00000000
        ? [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: shadowBlur,
              offset: Offset(0, shadowOffsetY),
            ),
          ]
        : null,
  );
}

EdgeInsets resolvePadding(ResolvedProperties props) {
  final p = (props['padding'] as num?)?.toDouble() ?? 12.0;
  return EdgeInsets.all(p);
}

Widget applyOpacity(Widget child, ResolvedProperties props) {
  final opacity = (props['opacity'] as num?)?.toDouble() ?? 1.0;
  if (opacity >= 1.0) return child;
  return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
}

TextStyle applyTextStyle(
  TextStyle base,
  ResolvedProperties props,
) {
  return base.copyWith(
    fontWeight: _parseFontWeight(props['fontWeight'] as String?),
    letterSpacing: (props['letterSpacing'] as num?)?.toDouble(),
  );
}

FontWeight? _parseFontWeight(String? raw) => switch (raw) {
      'normal' || 'w400' => FontWeight.w400,
      'bold' || 'w700' => FontWeight.w700,
      'w100' => FontWeight.w100,
      'w200' => FontWeight.w200,
      'w300' => FontWeight.w300,
      'w500' => FontWeight.w500,
      'w600' => FontWeight.w600,
      'w800' => FontWeight.w800,
      'w900' => FontWeight.w900,
      _ => null,
    };
