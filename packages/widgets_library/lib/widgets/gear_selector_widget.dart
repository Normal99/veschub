library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class GearSelectorWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const GearSelectorWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final currentGear = properties['currentGear'] as String? ?? 'P';
    final activeColor = Color((properties['activeColor'] as int?) ?? 0xFFFFFFFF);
    final inactiveColor = Color((properties['inactiveColor'] as int?) ?? 0xFF444444);
    final fontSizeRaw = (properties['fontSize'] as num?) ?? 24.0;
    final gears = properties['gears'] as String? ?? 'P,R,N,D';
    final gearList = gears.split(',').map((s) => s.trim()).toList();

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < gearList.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Text(
                  gearList[i],
                  style: TextStyle(
                    color: gearList[i] == currentGear ? activeColor : inactiveColor,
                    fontSize: fontSizeRaw.toDouble(),
                    fontWeight: gearList[i] == currentGear ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      properties,
    );
  }
}
