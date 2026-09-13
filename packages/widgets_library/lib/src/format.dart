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

// ─────────────────────────────────────────────────────────────────
// Per-widget unit conversion.
//
// VESC telemetry always arrives in one canonical unit per quantity
// (temperature in °C, speed derived in m/s via erpmToWheelRpm +
// wheelRpmToSpeed above). Not every user wants those units displayed,
// though — one widget might want °F, another km/h, another mph on the
// same dashboard. These helpers convert between a widget's declared
// *source* unit (what its bound value is already in) and its *display*
// unit (what to show), so that choice lives per-widget rather than as
// one global metric/imperial toggle.

enum TemperatureUnit { celsius, fahrenheit, kelvin }

/// Parses a unit property string (e.g. `'fahrenheit'`), defaulting to
/// Celsius for anything unrecognised — the canonical unit VESC telemetry
/// itself uses, so an absent/invalid property is a safe no-op.
TemperatureUnit temperatureUnitFromString(String? s) => switch (s) {
      'fahrenheit' || 'f' => TemperatureUnit.fahrenheit,
      'kelvin' || 'k' => TemperatureUnit.kelvin,
      _ => TemperatureUnit.celsius,
    };

String temperatureUnitSuffix(TemperatureUnit u) => switch (u) {
      TemperatureUnit.celsius => '°C',
      TemperatureUnit.fahrenheit => '°F',
      TemperatureUnit.kelvin => 'K',
    };

double _temperatureToCelsius(double value, TemperatureUnit from) =>
    switch (from) {
      TemperatureUnit.celsius => value,
      TemperatureUnit.fahrenheit => (value - 32) * 5 / 9,
      TemperatureUnit.kelvin => value - 273.15,
    };

double _celsiusTo(double celsius, TemperatureUnit to) => switch (to) {
      TemperatureUnit.celsius => celsius,
      TemperatureUnit.fahrenheit => celsius * 9 / 5 + 32,
      TemperatureUnit.kelvin => celsius + 273.15,
    };

/// Converts [value] from [from] to [to] (any pair of temperature units).
double convertTemperature(
  double value, {
  required TemperatureUnit from,
  required TemperatureUnit to,
}) =>
    _celsiusTo(_temperatureToCelsius(value, from), to);

enum SpeedUnit { kmh, mph, ms }

/// Parses a unit property string (e.g. `'mph'`), defaulting to km/h.
SpeedUnit speedUnitFromString(String? s) => switch (s) {
      'mph' => SpeedUnit.mph,
      'ms' || 'm/s' => SpeedUnit.ms,
      _ => SpeedUnit.kmh,
    };

String speedUnitSuffix(SpeedUnit u) => switch (u) {
      SpeedUnit.kmh => 'km/h',
      SpeedUnit.mph => 'mph',
      SpeedUnit.ms => 'm/s',
    };

double _speedToMs(double value, SpeedUnit from) => switch (from) {
      SpeedUnit.ms => value,
      SpeedUnit.kmh => value / 3.6,
      SpeedUnit.mph => value * 0.44704,
    };

double _msTo(double ms, SpeedUnit to) => switch (to) {
      SpeedUnit.ms => ms,
      SpeedUnit.kmh => ms * 3.6,
      SpeedUnit.mph => ms * 2.2369362920544025,
    };

/// Converts [value] from [from] to [to] (any pair of speed units).
double convertSpeed(
  double value, {
  required SpeedUnit from,
  required SpeedUnit to,
}) =>
    _msTo(_speedToMs(value, from), to);
