/// Settings screen for the dashboard runtime: theme, transport, auto-connect,
/// data rate, and unit preferences.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import '../display_settings.dart';

class DashboardSettingsScreen extends ConsumerWidget {
  const DashboardSettingsScreen({super.key});

  static const _rates = [5, 10, 20, 50];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    final display = ref.watch(displaySettingsProvider);
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
          const _SectionHeader('Display'),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_high),
            title: const Text('Keep screen awake'),
            subtitle: const Text(
                'Prevent the screen from sleeping while the dashboard is open '
                '— on by default for a display mounted in a vehicle.'),
            value: display.keepScreenAwake,
            onChanged: display.setKeepScreenAwake,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.fullscreen),
            title: const Text('Immersive fullscreen'),
            subtitle: const Text(
                "Hide the OS status/navigation bars entirely. Off by default "
                "— on some devices you'll need a swipe-from-edge gesture to "
                "get them back."),
            value: display.immersiveFullscreen,
            onChanged: display.setImmersiveFullscreen,
          ),
          const _SectionHeader('Connection'),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Transport'),
            subtitle: const Text('Preferred connection type.'),
            trailing: DropdownButton<TransportPreference>(
              value: settings.transport,
              items: const [
                DropdownMenuItem(
                    value: TransportPreference.auto, child: Text('Auto')),
                DropdownMenuItem(
                    value: TransportPreference.ble, child: Text('Bluetooth')),
                DropdownMenuItem(
                    value: TransportPreference.usb, child: Text('USB Serial')),
              ],
              onChanged: (v) => v == null ? null : settings.setTransport(v),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.power),
            title: const Text('Auto-connect'),
            subtitle:
                const Text('Connect to the preferred transport on app launch.'),
            value: settings.autoConnect,
            onChanged: settings.setAutoConnect,
          ),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Data rate'),
            subtitle: Text('Throttle telemetry updates to '
                '${settings.dataRate} Hz.'),
            trailing: DropdownButton<int>(
              value: settings.dataRate,
              items: _rates
                  .map((r) => DropdownMenuItem(value: r, child: Text('$r Hz')))
                  .toList(),
              onChanged: (v) => v == null ? null : settings.setDataRate(v),
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
