/// Settings screen for the dashboard runtime: theme + transport preference.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import '../providers/settings_provider.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

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
          const _SectionHeader('Connection'),
          ListTile(
            leading: const Icon(Icons.cable),
            title: const Text('Transport'),
            subtitle: const Text('How the runtime connects to your VESC.'),
            trailing: DropdownButton<TransportPreference>(
              value: settings.transport,
              items: TransportPreference.values
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(_transportLabel(t)),
                      ))
                  .toList(),
              onChanged: (v) => v == null ? null : settings.setTransport(v),
            ),
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

String _transportLabel(TransportPreference t) => switch (t) {
      TransportPreference.ble => 'BLE',
      TransportPreference.usb => 'USB',
      TransportPreference.auto => 'Auto',
    };
