library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class StatusBarWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const StatusBarWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final time = properties['time'] as String? ?? _currentTime();
    final battery = (properties['battery'] as num?)?.toDouble();
    final signal = (properties['signal'] as num?)?.toDouble();
    final showBattery = properties['showBattery'] as bool? ?? true;
    final showSignal = properties['showSignal'] as bool? ?? true;
    final showTime = properties['showTime'] as bool? ?? true;
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 13.0;

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showTime)
                Text(
                  time,
                  style: applyTextStyle(
                    TextStyle(color: color, fontSize: fontSizeRaw.toDouble(), fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
                    properties,
                  ),
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showSignal && signal != null) ...[
                    _SignalIcon(level: signal.clamp(0.0, 1.0), color: color, size: fontSizeRaw.toDouble()),
                    const SizedBox(width: 6),
                  ],
                  if (showBattery && battery != null) ...[
                    _BatteryIcon(level: battery.clamp(0.0, 1.0), color: color, size: fontSizeRaw.toDouble()),
                    const SizedBox(width: 2),
                    Text(
                      '${(battery * 100).round()}%',
                      style: TextStyle(color: accent, fontSize: fontSizeRaw.toDouble() * 0.85, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
      properties,
    );
  }

  String _currentTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}

class _SignalIcon extends StatelessWidget {
  final double level;
  final Color color;
  final double size;
  const _SignalIcon({required this.level, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final bars = (level * 4).round().clamp(1, 4);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < bars;
        return Container(
          width: size * 0.2,
          height: size * (0.3 + i * 0.2),
          margin: EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}

class _BatteryIcon extends StatelessWidget {
  final double level;
  final Color color;
  final double size;
  const _BatteryIcon({required this.level, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final icon = level > 0.6
        ? Icons.battery_full
        : level > 0.3
            ? Icons.battery_5_bar
            : level > 0.15
                ? Icons.battery_3_bar
                : Icons.battery_alert;
    return Icon(icon, color: color, size: size * 1.2);
  }
}
