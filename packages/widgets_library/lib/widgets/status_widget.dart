/// A status widget that reflects the VESC fault code and a bound "state" value.
///
/// Renders a coloured pill + label; the colour reflects severity (green = ok,
/// amber = warning, red = fault). Useful as a top-of-dashboard health indicator.
library;

import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:flutter/material.dart';

import '../src/theme.dart';

/// Renders a `status` widget from resolved properties:
///  * `fault`   — fault code (int; 0 = none)
///  * `label`   — optional override label (default: derived from fault)
///  * `value`   — optional secondary state text
class StatusWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const StatusWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = DashboardThemeProvider.of(context);
    final fault = (properties['fault'] as num?)?.toInt() ?? 0;
    final (severity, color) = _severity(fault, theme);
    final label = properties['label'] as String? ?? _faultLabel(fault);
    final value = properties['value']?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(severity.icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (value != null)
                Text(
                  value,
                  style: TextStyle(color: theme.secondary, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (_Severity, Color) _severity(int fault, DashboardTheme theme) {
    if (fault == 0) {
      return (_Severity.ok, theme.chartPalette[2]); // green-ish
    }
    if (fault <= 2 || fault >= 12) {
      // voltage faults / reserved → warning
      return (_Severity.warning, theme.chartPalette[1]); // amber
    }
    return (_Severity.critical, theme.chartPalette[3]); // red
  }

  String _faultLabel(int fault) {
    if (fault == 0) return 'OK';
    return 'Fault $fault';
  }
}

enum _Severity { ok, warning, critical }

extension on _Severity {
  IconData get icon => switch (this) {
        _Severity.ok => Icons.check_circle,
        _Severity.warning => Icons.warning,
        _Severity.critical => Icons.error,
      };
}
