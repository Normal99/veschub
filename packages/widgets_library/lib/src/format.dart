/// Unit + value formatting helpers for widget renderers.
///
/// VESC telemetry arrives in SI units (amps, volts, eRPM, °C). Dashboards
/// display these with sensible precision and optional unit suffixes; this
/// module centralises the formatting so all widgets are consistent.
library;

/// Formats a numeric [value] with [decimals] and returns a human-readable
/// string, using tabular-friendly figures.
///
///  * Integers or whole-valued floats with [decimals] == 0 → no decimal point.
///  * Large magnitudes use thousands separators (e.g. `12,300`).
String formatNumber(num value, {int decimals = 1}) {
  if (value.isNaN || value.isInfinite) return '--';
  final abs = value.abs();
  // Whole numbers render without decimals when decimals == 0.
  if (decimals == 0 && value == value.roundToDouble()) {
    return _group(value.round());
  }
  if (abs >= 1000) {
    return _group(value.toStringAsFixed(0));
  }
  return value.toStringAsFixed(decimals);
}

String _group(Object n) {
  final s = n.toString();
  final isNegative = s.startsWith('-');
  final digits = isNegative ? s.substring(1) : s;
  final buf = StringBuffer(isNegative ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}

/// Converts an electrical RPM to a mechanical wheel RPM given [motorPoles]
/// (pole pairs) and an optional [gearRatio] (e.g. pulley ratio).
double erpmToWheelRpm(int erpm, {int motorPoles = 14, double gearRatio = 1.0}) {
  if (motorPoles == 0) return 0;
  return erpm / (motorPoles / 2) / gearRatio;
}

/// Estimates speed (m/s) from wheel RPM and wheel diameter (mm).
double wheelRpmToSpeed(double wheelRpm, double wheelDiameterMm) {
  final circumference = wheelDiameterMm / 1000 * 3.141592653589793;
  return wheelRpm / 60 * circumference;
}

/// Formats a distance in metres as km (with `km` suffix) or m.
String formatDistance(double metres) {
  if (metres >= 1000) {
    return '${formatNumber(metres / 1000, decimals: 2)} km';
  }
  return '${formatNumber(metres, decimals: 0)} m';
}

/// Formats an energy value in watt-hours.
String formatWattHours(double wh) {
  if (wh.abs() >= 1000) {
    return '${formatNumber(wh / 1000, decimals: 2)} kWh';
  }
  return '${formatNumber(wh, decimals: 1)} Wh';
}

/// Formats a current in amps.
String formatAmps(double amps) => '${formatNumber(amps, decimals: 1)} A';

/// Formats a voltage.
String formatVolts(double volts) => '${formatNumber(volts, decimals: 1)} V';

/// Formats a temperature in °C.
String formatCelsius(double c) => '${formatNumber(c, decimals: 0)} °C';
