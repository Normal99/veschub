library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class MapWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const MapWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF4488FF);
    final label = properties['label'] as String? ?? 'Navigation';
    final eta = properties['eta'] as String?;
    final distance = properties['distance'] as String?;
    final nextTurn = properties['nextTurn'] as String?;
    final showMapGraphic = properties['showMapGraphic'] as bool? ?? true;
    final mapStyle = properties['mapStyle'] as String? ?? 'vector';
    final isLiveTiles = mapStyle == 'osm';

    final width = (properties['width'] as num?)?.toDouble();
    final height = (properties['height'] as num?)?.toDouble();

    return applyOpacity(
      SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: resolveBoxDecoration(properties),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isLiveTiles)
                Positioned.fill(
                  child: _LiveMapTiles(properties: properties, accent: accent),
                ),
              if (showMapGraphic && !isLiveTiles)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapCanvasPainter(
                      accentColor: accent,
                      style: mapStyle,
                    ),
                  ),
                ),
              if (!showMapGraphic && !isLiveTiles)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map,
                          color: color.withValues(alpha: 0.3), size: 48),
                      const SizedBox(height: 8),
                      Text(label,
                          style: TextStyle(
                              color: color.withValues(alpha: 0.5),
                              fontSize: 14)),
                    ],
                  ),
                ),
              if (nextTurn != null || eta != null)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xCC000000),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        if (nextTurn != null) ...[
                          Icon(Icons.navigation, color: accent, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(nextTurn,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold))),
                        ],
                        if (eta != null)
                          Text(eta,
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        if (distance != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Text(distance,
                                style: TextStyle(
                                    color: color.withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      properties,
    );
  }
}

/// Real OpenStreetMap tiles, centred on the bound `lat`/`lon` telemetry —
/// opt-in via `mapStyle: 'osm'` (default remains the decorative
/// `_MapCanvasPainter` graphic, so no existing dashboard's look changes).
/// Includes the on-map attribution OSM's tile usage policy requires.
class _LiveMapTiles extends StatelessWidget {
  final ResolvedProperties properties;
  final Color accent;
  const _LiveMapTiles({required this.properties, required this.accent});

  @override
  Widget build(BuildContext context) {
    final lat = (properties['lat'] as num?)?.toDouble();
    final lon = (properties['lon'] as num?)?.toDouble();
    final zoom = (properties['zoom'] as num?)?.toDouble() ?? 15.0;
    final heading = (properties['heading'] as num?)?.toDouble() ?? 0.0;

    if (lat == null || lon == null) {
      return ColoredBox(
        color: const Color(0xFF0F141C),
        child: Center(
          child: Text(
            'No GPS fix yet',
            style:
                TextStyle(color: accent.withValues(alpha: 0.6), fontSize: 13),
          ),
        ),
      );
    }

    final center = ll.LatLng(lat, lon);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.veschub.dashboard',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 28,
              height: 28,
              child: Transform.rotate(
                angle: heading * 3.141592653589793 / 180,
                child: Icon(Icons.navigation, color: accent, size: 28),
              ),
            ),
          ],
        ),
        // Required by OSM's tile usage policy — see
        // https://operations.osmfoundation.org/policies/tiles/
        const Align(
          alignment: Alignment.bottomRight,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0x99000000)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(color: Colors.white70, fontSize: 8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MapCanvasPainter extends CustomPainter {
  final Color accentColor;
  final String style;
  _MapCanvasPainter({required this.accentColor, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final isSatellite = style == 'satellite';
    final bgPaint = Paint()
      ..color = isSatellite ? const Color(0xFF15221B) : const Color(0xFF0F141C);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Terrain/Parks
    final parkPaint = Paint()
      ..color = isSatellite ? const Color(0xFF1C2E24) : const Color(0xFF141D18);
    final parkPath = Path()
      ..moveTo(size.width * 0.1, 0)
      ..lineTo(size.width * 0.4, 0)
      ..lineTo(size.width * 0.35, size.height * 0.4)
      ..lineTo(size.width * 0.05, size.height * 0.3)
      ..close();
    canvas.drawPath(parkPath, parkPaint);

    // Minor Roads
    final minorRoadPaint = Paint()
      ..color = isSatellite ? const Color(0xFF2C3E35) : const Color(0xFF1E2836)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final minorPath = Path();
    for (double y = 40; y < size.height; y += 70) {
      minorPath.moveTo(0, y);
      minorPath.lineTo(size.width, y + 20);
    }
    for (double x = 60; x < size.width; x += 110) {
      minorPath.moveTo(x, 0);
      minorPath.lineTo(x - 30, size.height);
    }
    canvas.drawPath(minorPath, minorRoadPaint);

    // Major Highway
    final majorRoadPaint = Paint()
      ..color = const Color(0xFF2E3B4E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final highwayPath = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..cubicTo(size.width * 0.3, size.height * 0.6, size.width * 0.4,
          size.height * 0.4, size.width * 0.8, 0);
    canvas.drawPath(highwayPath, majorRoadPaint);

    // Active Navigation Route Line (Cyan/Accent)
    final routeGlow = Paint()
      ..color = accentColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final routePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final routePath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.85)
      ..lineTo(size.width * 0.5, size.height * 0.5)
      ..cubicTo(size.width * 0.5, size.height * 0.35, size.width * 0.6,
          size.height * 0.3, size.width * 0.75, size.height * 0.2);
    canvas.drawPath(routePath, routeGlow);
    canvas.drawPath(routePath, routePaint);

    // Location Arrow (Vehicle position)
    final arrowCenter = Offset(size.width * 0.5, size.height * 0.85);
    final arrowPaint = Paint()..color = const Color(0xFF00E5FF);
    final arrowPath = Path()
      ..moveTo(arrowCenter.dx, arrowCenter.dy - 12)
      ..lineTo(arrowCenter.dx + 9, arrowCenter.dy + 10)
      ..lineTo(arrowCenter.dx, arrowCenter.dy + 5)
      ..lineTo(arrowCenter.dx - 9, arrowCenter.dy + 10)
      ..close();

    // Pulse halo around location arrow
    final haloPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(arrowCenter, 18, haloPaint);
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
