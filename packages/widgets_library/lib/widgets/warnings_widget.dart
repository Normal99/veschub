library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class WarningsWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const WarningsWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Color((properties['color'] as int?) ?? 0xFFFF4444);
    final warningColor = Color((properties['warningColor'] as int?) ?? 0xFFFFAA00);
    final infoColor = Color((properties['infoColor'] as int?) ?? 0xFF4488FF);
    final activeWarnings = properties['activeWarnings'] as String? ?? '';
    final iconSize = (properties['iconSize'] as num?)?.toDouble() ?? 24.0;

    final warnings = _parseWarnings(activeWarnings);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: warnings.isEmpty
                ? [
                    Icon(Icons.check_circle, color: const Color(0xFF00CC66), size: iconSize),
                    Text('OK', style: TextStyle(color: const Color(0xFF00CC66), fontSize: iconSize * 0.6)),
                  ]
                : warnings.map((w) => _WarningIcon(
                      icon: _iconFor(w.type),
                      color: _colorFor(w.type, color, warningColor, infoColor),
                      size: iconSize,
                      tooltip: w.message,
                    )).toList(),
          ),
        ),
      ),
      properties,
    );
  }

  List<_Warning> _parseWarnings(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',').map((s) {
      final parts = s.trim().split(':');
      final type = parts[0].trim();
      final msg = parts.length > 1 ? parts.sublist(1).join(':').trim() : type;
      return _Warning(type, msg);
    }).where((w) => w.type.isNotEmpty).toList();
  }

  IconData _iconFor(String type) => switch (type) {
        'battery' || 'bat' => Icons.battery_alert,
        'temp' || 'temperature' => Icons.thermostat,
        'motor' => Icons.electric_bike,
        'controller' || 'esc' => Icons.memory,
        'brake' => Icons.warning,
        'tire' || 'pressure' => Icons.tire_repair,
        'belt' => Icons.settings,
        'fault' || 'error' => Icons.error_outline,
        'signal' => Icons.signal_wifi_bad,
        'gps' => Icons.gps_off,
        'lights' => Icons.lightbulb_outline,
        'door' => Icons.meeting_room,
        'seatbelt' => Icons.airline_seat_recline_extra,
        'oil' => Icons.oil_barrel,
        'engine' || 'check' => Icons.build_circle,
        _ => Icons.warning_amber,
      };

  Color _colorFor(String type, Color error, Color warning, Color info) {
    if (type == 'fault' || type == 'error' || type == 'motor' || type == 'brake') return error;
    if (type == 'temp' || type == 'battery' || type == 'oil' || type == 'engine') return warning;
    return info;
  }
}

class _Warning {
  final String type;
  final String message;
  _Warning(this.type, this.message);
}

class _WarningIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String tooltip;

  const _WarningIcon({
    required this.icon,
    required this.color,
    required this.size,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: size),
    );
  }
}
