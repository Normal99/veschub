import 'package:flutter/material.dart';

import 'package:dashboard_runtime/dashboard_runtime.dart';

BoxDecoration resolveBoxDecoration(ResolvedProperties props) {
  final bgColor = propColor(props, 'backgroundColor', 0x00000000);
  final borderRadiusRaw = propDouble(props, 'borderRadius', 0.0);
  final borderWidth = propDouble(props, 'borderWidth', 0.0);
  final borderColor = propColor(props, 'borderColor', 0xFFFFFFFF);
  final shadowColor = propColor(props, 'shadowColor', 0x00000000);
  final shadowBlur = propDouble(props, 'shadowBlur', 0.0);
  final shadowOffsetY = propDouble(props, 'shadowOffsetY', 2.0);

  return BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(borderRadiusRaw),
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
  final p = propDouble(props, 'padding', 12.0);
  return EdgeInsets.all(p);
}

Widget applyOpacity(Widget child, ResolvedProperties props) {
  final opacity = propDouble(props, 'opacity', 1.0);
  if (opacity >= 1.0) return child;
  return Opacity(opacity: opacity.clamp(0.0, 1.0), child: child);
}

TextStyle applyTextStyle(
  TextStyle base,
  ResolvedProperties props,
) {
  final fontFamily = props['fontFamily'] is String ? props['fontFamily'] as String : null;
  final fontWeightRaw = props['fontWeight'] is String ? props['fontWeight'] as String : null;
  return base.copyWith(
    fontFamily: fontFamily,
    fontWeight: _parseFontWeight(fontWeightRaw),
    letterSpacing: propDoubleOpt(props, 'letterSpacing'),
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

// ─────────────────────────────────────────────────────────────────
// Safe property accessors
// These handle mismatched runtime types gracefully (e.g. String
// passed instead of num) so widgets never crash on bad input.
// ─────────────────────────────────────────────────────────────────

/// Safely read a double from [props], with [fallback] as default.
double propDouble(ResolvedProperties props, String key, double fallback) {
  final v = props[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

/// Safely read an int from [props], with [fallback] as default.
int propInt(ResolvedProperties props, String key, int fallback) {
  final v = props[key];
  if (v is num) return v.toInt();
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// Safely read an ARGB color int from [props], with [fallback] as default.
Color propColor(ResolvedProperties props, String key, int fallback) {
  final v = props[key];
  if (v is int) return Color(v);
  if (v is num) return Color(v.toInt());
  return Color(fallback);
}

/// Safely read a bool from [props], with [fallback] as default.
bool propBool(ResolvedProperties props, String key, {bool fallback = false}) {
  final v = props[key];
  if (v is bool) return v;
  if (v == 1 || v == 'true') return true;
  if (v == 0 || v == 'false') return false;
  return fallback;
}

/// Safely read a nullable double from [props].
double? propDoubleOpt(ResolvedProperties props, String key) {
  final v = props[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
