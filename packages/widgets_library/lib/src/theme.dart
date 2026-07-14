/// Theming helpers shared by studio and dashboard apps.
///
/// A dashboard document carries `background` and `accent` ARGB ints (see
/// [DashboardDocument]); these helpers resolve a full [DashboardTheme] from
/// those plus a brightness choice. Widget renderers consume the resolved theme
/// rather than hardcoding colours.
library;

import 'package:flutter/material.dart';

/// A resolved dashboard theme: surface/foreground + accent + chart palette.
@immutable
class DashboardTheme {
  final Color background;
  final Color foreground;
  final Color accent;
  final Color secondary;
  final Brightness brightness;

  /// A categorical palette for multi-series charts.
  final List<Color> chartPalette;

  const DashboardTheme({
    required this.background,
    required this.foreground,
    required this.accent,
    required this.secondary,
    required this.brightness,
    this.chartPalette = const [
      Color(0xFF4FC3F7),
      Color(0xFFFFB74D),
      Color(0xFFAED581),
      Color(0xFFEF5350),
      Color(0xFFCE93D8),
    ],
  });

  /// Dark theme (the dashboard runtime default).
  static const dark = DashboardTheme(
    background: Color(0xFF000000),
    foreground: Color(0xFFFFFFFF),
    accent: Color(0xFFE0E0E0),
    secondary: Color(0xFF9E9E9E),
    brightness: Brightness.dark,
  );

  /// Light theme.
  static const light = DashboardTheme(
    background: Color(0xFFFAFAFA),
    foreground: Color(0xFF212121),
    accent: Color(0xFF1565C0),
    secondary: Color(0xFF757575),
    brightness: Brightness.light,
  );

  /// Resolves a theme from a dashboard document's colour ints.
  factory DashboardTheme.fromDocument({
    required int backgroundArgb,
    required int accentArgb,
    Brightness brightness = Brightness.dark,
  }) {
    final bg = Color(backgroundArgb);
    final accent = Color(accentArgb);
    final fg = brightness == Brightness.dark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF212121);
    return DashboardTheme(
      background: bg,
      foreground: fg,
      accent: accent,
      secondary: fg.withValues(alpha: 0.6),
      brightness: brightness,
    );
  }

  DashboardTheme copyWith({
    Color? background,
    Color? foreground,
    Color? accent,
    Color? secondary,
    Brightness? brightness,
    List<Color>? chartPalette,
  }) =>
      DashboardTheme(
        background: background ?? this.background,
        foreground: foreground ?? this.foreground,
        accent: accent ?? this.accent,
        secondary: secondary ?? this.secondary,
        brightness: brightness ?? this.brightness,
        chartPalette: chartPalette ?? this.chartPalette,
      );
}

/// Inherited widget exposing the current [DashboardTheme] down the tree.
class DashboardThemeProvider extends InheritedWidget {
  final DashboardTheme theme;
  const DashboardThemeProvider({
    required this.theme,
    required super.child,
    super.key,
  });

  static DashboardTheme of(BuildContext context) {
    final w =
        context.dependOnInheritedWidgetOfExactType<DashboardThemeProvider>();
    return w?.theme ?? DashboardTheme.dark;
  }

  @override
  bool updateShouldNotify(DashboardThemeProvider oldWidget) =>
      oldWidget.theme != theme;
}
