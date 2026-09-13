/// Veschub Studio — the dashboard editor app.
///
/// Boots the persisted [SettingsService], shows first-run onboarding when
/// needed, applies the chosen theme, and lands on the editor. The toolbar's
/// mode/level selectors remain the in-session controls; the settings screen
/// holds the persisted defaults.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import 'editor/studio_editor.dart';
import 'onboarding/studio_onboarding.dart';
import 'settings/studio_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await createSettingsService();
  await registerAllCustomFonts(settings);
  runApp(
    ProviderScope(
      overrides: [settingsServiceProvider.overrideWith((ref) => settings)],
      child: const StudioApp(),
    ),
  );
}

class StudioApp extends ConsumerWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);

    final themeMode = switch (settings.themeMode) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };
    return MaterialApp(
      title: 'Veschub Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: themeMode,
      home: settings.onboardingDone
          ? const StudioEditor()
          : const StudioOnboarding(),
      routes: {
        '/settings': (_) => const StudioSettingsScreen(),
      },
    );
  }
}
