/// A compact GPS readout: speed, altitude, and coordinates together — the
/// composite panel a real GPS-equipped instrument cluster shows, distinct
/// from the `map` kind's live tile view.
library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class GpsWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const GpsWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final speed = (properties['speed'] as num?)?.toDouble();
    final altitude = (properties['altitude'] as num?)?.toDouble();
    final lat = (properties['lat'] as num?)?.toDouble();
    final lon = (properties['lon'] as num?)?.toDouble();
    final unit = properties['unit'] as String? ?? 'km/h';
    final showCoordinates = properties['showCoordinates'] as bool? ?? true;
    final color = propColor(properties, 'color', 0xFFFFFFFF);
    final accent = propColor(properties, 'accent', 0xFF888888);
    final fontSizeRaw = propDouble(properties, 'fontSize', 36.0);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          // FittedBox absorbs the case where the three stacked lines are a
          // few pixels taller than the widget's box (a small height, or a
          // larger fontSize than the box was sized for) by scaling down
          // instead of throwing a RenderFlex overflow — the same defensive
          // pattern text_widget.dart/tripstats_widget.dart/
          // digitalspeed_widget.dart already use for the same reason.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Icon(Icons.satellite_alt,
                        color: accent, size: fontSizeRaw * 0.4),
                    const SizedBox(width: 6),
                    Text(
                      _formatSpeed(speed),
                      style: applyTextStyle(
                        TextStyle(
                          color: color,
                          fontSize: fontSizeRaw,
                          fontWeight: FontWeight.w500,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        properties,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(unit,
                          style: TextStyle(
                              color: accent, fontSize: fontSizeRaw * 0.35)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Alt: ${_formatAltitude(altitude)}',
                  style: TextStyle(color: accent, fontSize: fontSizeRaw * 0.3),
                ),
                if (showCoordinates) ...[
                  const SizedBox(height: 2),
                  Text(
                    _formatCoordinates(lat, lon),
                    style: TextStyle(
                      color: accent.withValues(alpha: 0.8),
                      fontSize: fontSizeRaw * 0.28,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      properties,
    );
  }

  String _formatSpeed(double? v) => v == null ? '--' : v.toStringAsFixed(0);

  String _formatAltitude(double? v) =>
      v == null ? '-- m' : '${v.toStringAsFixed(0)} m';

  String _formatCoordinates(double? lat, double? lon) {
    if (lat == null || lon == null) return 'No GPS fix yet';
    final latHemi = lat >= 0 ? 'N' : 'S';
    final lonHemi = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}°$latHemi, '
        '${lon.abs().toStringAsFixed(4)}°$lonHemi';
  }
}
