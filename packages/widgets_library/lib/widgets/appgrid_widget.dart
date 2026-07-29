library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class AppGridWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const AppGridWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final apps = properties['apps'] as String? ?? 'phone,music,maps,messages,settings';
    final columns = (properties['columns'] as num?)?.toInt() ?? 4;
    final iconSize = (properties['iconSize'] as num?)?.toDouble() ?? 28.0;
    final showLabels = properties['showLabels'] as bool? ?? true;
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 11.0;

    final appList = apps.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 8,
            childAspectRatio: showLabels ? 0.85 : 1.0,
            children: appList.map((app) {
              final parts = app.split(':');
              final name = parts[0];
              final customLabel = parts.length > 1 ? parts[1] : null;
              return _AppTile(
                name: name,
                label: customLabel ?? _labelFor(name),
                icon: _iconFor(name),
                color: color,
                accent: accent,
                iconSize: iconSize,
                fontSize: fontSizeRaw.toDouble(),
                showLabel: showLabels,
              );
            }).toList(),
          ),
        ),
      ),
      properties,
    );
  }

  String _labelFor(String name) => switch (name) {
        'phone' => 'Phone',
        'music' => 'Music',
        'maps' || 'navigation' || 'nav' => 'Maps',
        'messages' || 'sms' => 'Messages',
        'settings' || 'gear' => 'Settings',
        'calendar' => 'Calendar',
        'weather' => 'Weather',
        'camera' => 'Camera',
        'photos' => 'Photos',
        'clock' => 'Clock',
        'calculator' => 'Calc',
        'notes' => 'Notes',
        'browser' || 'web' => 'Browser',
        'email' || 'mail' => 'Mail',
        'podcasts' => 'Podcasts',
        'audiobooks' => 'Audiobooks',
        'radio' => 'Radio',
        'obd' || 'diagnostics' => 'Diagnostics',
        'dashboard' => 'Dashboard',
        'tesla' => 'Tesla',
        _ => name[0].toUpperCase() + name.substring(1),
      };

  IconData _iconFor(String name) => switch (name) {
        'phone' => Icons.phone,
        'music' => Icons.music_note,
        'maps' || 'navigation' || 'nav' => Icons.map,
        'messages' || 'sms' => Icons.message,
        'settings' || 'gear' => Icons.settings,
        'calendar' => Icons.calendar_today,
        'weather' => Icons.wb_sunny,
        'camera' => Icons.camera_alt,
        'photos' => Icons.photo_library,
        'clock' => Icons.access_time,
        'calculator' => Icons.calculate,
        'notes' => Icons.note,
        'browser' || 'web' => Icons.language,
        'email' || 'mail' => Icons.email,
        'podcasts' => Icons.podcasts,
        'audiobooks' => Icons.headphones,
        'radio' => Icons.radio,
        'obd' || 'diagnostics' => Icons.build,
        'dashboard' => Icons.dashboard,
        'tesla' => Icons.electric_car,
        _ => Icons.apps,
      };
}

class _AppTile extends StatelessWidget {
  final String name;
  final String label;
  final IconData icon;
  final Color color;
  final Color accent;
  final double iconSize;
  final double fontSize;
  final bool showLabel;

  const _AppTile({
    required this.name,
    required this.label,
    required this.icon,
    required this.color,
    required this.accent,
    required this.iconSize,
    required this.fontSize,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: iconSize * 1.8,
          height: iconSize * 1.8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(iconSize * 0.4),
          ),
          child: Icon(icon, color: color, size: iconSize),
        ),
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              label,
              style: TextStyle(color: accent, fontSize: fontSize),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
