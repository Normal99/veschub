/// Canonical telemetry field keys used across veschub.
///
/// Dot-delimited namespaces group related fields (e.g. `current.motor`,
/// `temp.motor`, `gps.lat`). Widgets bind properties to these keys; the runtime
/// re-evaluates bindings when a key's value changes.
library;

/// All canonical telemetry keys.
class TelemetryKey {
  TelemetryKey._();

  static const erpm = 'erpm';
  static const duty = 'duty';

  static const currentMotor = 'current.motor';
  static const currentInput = 'current.input';

  static const vIn = 'v_in';

  static const tempMotor = 'temp.motor';
  static const tempMosfet = 'temp.mosfet';

  /// FOC d/q-axis currents (only meaningful in FOC motor control mode).
  static const focId = 'foc.id';
  static const focIq = 'foc.iq';

  static const ampHoursCharged = 'amp_hours.charged';
  static const ampHoursDischarged = 'amp_hours.discharged';
  static const wattHoursCharged = 'watt_hours.charged';
  static const wattHoursDischarged = 'watt_hours.discharged';

  static const tachometer = 'tachometer';
  static const tachometerAbs = 'tachometer_abs';

  static const fault = 'fault';

  // GPS namespace (populated from a GPS source, not the base VESC values packet).
  static const gpsLat = 'gps.lat';
  static const gpsLon = 'gps.lon';
  static const gpsSpeed = 'gps.speed';
  static const gpsHeading = 'gps.heading';
  static const gpsAltitude = 'gps.altitude';

  /// All keys, useful for tests and the studio palette.
  static const all = <String>[
    erpm,
    duty,
    currentMotor,
    currentInput,
    vIn,
    tempMotor,
    tempMosfet,
    focId,
    focIq,
    ampHoursCharged,
    ampHoursDischarged,
    wattHoursCharged,
    wattHoursDischarged,
    tachometer,
    tachometerAbs,
    fault,
    gpsLat,
    gpsLon,
    gpsSpeed,
    gpsHeading,
    gpsAltitude,
  ];
}

/// A human-readable name for a canonical telemetry key, for a picker UI
/// (Studio's binding editor) rather than someone who already knows the raw
/// VESC field names. Falls back to the raw key itself for anything outside
/// [TelemetryKey.all] — a custom LispBM variable, or any other
/// non-canonical key a dashboard might bind to.
String telemetryKeyLabel(String key) => switch (key) {
      TelemetryKey.erpm => 'Motor Speed (ERPM)',
      TelemetryKey.duty => 'Duty Cycle',
      TelemetryKey.currentMotor => 'Motor Current',
      TelemetryKey.currentInput => 'Battery Current',
      TelemetryKey.vIn => 'Battery Voltage',
      TelemetryKey.tempMotor => 'Motor Temperature',
      TelemetryKey.tempMosfet => 'Controller Temperature',
      TelemetryKey.focId => 'FOC D-Axis Current',
      TelemetryKey.focIq => 'FOC Q-Axis Current',
      TelemetryKey.ampHoursCharged => 'Amp Hours Charged',
      TelemetryKey.ampHoursDischarged => 'Amp Hours Discharged',
      TelemetryKey.wattHoursCharged => 'Watt Hours Charged',
      TelemetryKey.wattHoursDischarged => 'Watt Hours Discharged',
      TelemetryKey.tachometer => 'Tachometer (Distance)',
      TelemetryKey.tachometerAbs => 'Tachometer (Absolute)',
      TelemetryKey.fault => 'Fault Code',
      TelemetryKey.gpsLat => 'GPS Latitude',
      TelemetryKey.gpsLon => 'GPS Longitude',
      TelemetryKey.gpsSpeed => 'GPS Speed',
      TelemetryKey.gpsHeading => 'GPS Heading',
      TelemetryKey.gpsAltitude => 'GPS Altitude',
      _ => key,
    };
