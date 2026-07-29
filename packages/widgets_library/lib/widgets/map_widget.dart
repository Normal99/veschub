library;

import 'package:flutter/material.dart';
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

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, color: color.withValues(alpha: 0.3), size: 48),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 14)),
                ],
              ),
            ),
            if (nextTurn != null || eta != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xCC000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      if (nextTurn != null) ...[
                        Icon(Icons.navigation, color: accent, size: 16),
                        const SizedBox(width: 6),
                        Expanded(child: Text(nextTurn, style: const TextStyle(color: Colors.white, fontSize: 13))),
                      ],
                      if (eta != null)
                        Text(eta, style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w600)),
                      if (distance != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(distance, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      properties,
    );
  }
}
