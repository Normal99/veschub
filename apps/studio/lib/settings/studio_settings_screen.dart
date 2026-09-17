/// Settings screen for the studio: theme, custom fonts.
///
/// Backed by the shared [SettingsService]; changes persist immediately and
/// notify listeners (the app reacts to theme changes live).
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import '../fonts/custom_font_service.dart';

class StudioSettingsScreen extends ConsumerWidget {
  const StudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemePreference>(
              value: settings.themeMode,
              items: const [
                DropdownMenuItem(
                    value: ThemePreference.system, child: Text('System')),
                DropdownMenuItem(
                    value: ThemePreference.light, child: Text('Light')),
                DropdownMenuItem(
                    value: ThemePreference.dark, child: Text('Dark')),
              ],
              onChanged: (v) => v == null ? null : settings.setThemeMode(v),
            ),
          ),
          const _SectionHeader('Custom Fonts'),
          for (final font in settings.customFonts)
            ListTile(
              leading: const Icon(Icons.font_download_outlined),
              title:
                  Text(font.family, style: TextStyle(fontFamily: font.family)),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remove custom font',
                onPressed: () => removeCustomFont(settings, font),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Import font (.ttf / .otf)'),
            subtitle: const Text(
              'Available in any dashboard\'s font picker afterwards.',
            ),
            onTap: () async {
              final family = await importCustomFont(settings);
              if (family != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported "$family"')),
                );
              }
            },
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Studio v0.1.0 · document schema '
                '$kCurrentDocumentVersion'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
