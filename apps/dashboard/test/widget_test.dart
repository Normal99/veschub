import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:widgets_library/widgets_library.dart';

import 'package:dashboard/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
    });
  });

  testWidgets('dashboard app boots and renders the sim viewer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DashboardApp()));

    // Let the async SettingsService resolve before the viewer mounts.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // App chrome renders once the viewer is up.
    expect(find.text('Veschub · Sim viewer'), findsOneWidget);

    // The runtime's first dirty emit (with literal bindings resolved) lands on
    // a subsequent frame. Pump a few frames (not pumpAndSettle — the sim's
    // periodic timer would time that out) so the bound widget labels appear.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Literal-bound labels from the sample document are now resolved.
    expect(find.text('RPM'), findsOneWidget);
    expect(find.text('Pack voltage'), findsOneWidget);
  });

  testWidgets(
      'viewer provides a DashboardThemeProvider so widgets never fall back '
      'to the hardcoded dark default', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DashboardApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final theme = DashboardThemeProvider.of(tester.element(
      find
          .descendant(
            of: find.byType(DashboardThemeProvider),
            matching: find.byType(ColoredBox),
          )
          .first,
    ));
    // A real theme was resolved from the document, not the ambient default.
    expect(theme, isNot(same(DashboardTheme.dark)));
    expect(theme.background, isNotNull);
  });

  testWidgets('the provided theme brightness follows the resolved ThemeMode',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.themeMode': 'light',
    });
    await tester.pumpWidget(const ProviderScope(child: DashboardApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final theme = DashboardThemeProvider.of(tester.element(
      find
          .descendant(
            of: find.byType(DashboardThemeProvider),
            matching: find.byType(ColoredBox),
          )
          .first,
    ));
    expect(theme.brightness, Brightness.light);
  });
}
