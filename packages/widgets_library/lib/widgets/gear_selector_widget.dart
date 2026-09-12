library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class GearSelectorWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const GearSelectorWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final currentGear = properties['currentGear']?.toString() ?? 'P';
    final activeColorVal = properties['activeColor'];
    final activeColor = Color(activeColorVal is int ? activeColorVal : 0xFFFFFFFF);
    final inactiveColorVal = properties['inactiveColor'];
    final inactiveColor = Color(inactiveColorVal is int ? inactiveColorVal : 0xFF444444);
    final fontSizeVal = properties['fontSize'];
    final fontSize = (fontSizeVal is num ? fontSizeVal.toDouble() : null) ?? 24.0;
    final gears = properties['gears']?.toString() ?? 'P,R,N,D';
    final gearList = gears.split(',').map((s) => s.trim()).toList();

    return applyOpacity(
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
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
                    style: applyTextStyle(
                      TextStyle(
                        color: gearList[i] == currentGear ? activeColor : inactiveColor,
                        fontSize: fontSize,
                        fontWeight: gearList[i] == currentGear ? FontWeight.w700 : FontWeight.w400,
                      ),
                      properties,
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
}
