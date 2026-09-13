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
