/// Helpers that bridge decoded VESC packets into canonical [TelemetryKey]s.
library;

import 'telemetry_key.dart';
import 'telemetry_store.dart';

/// Extension that writes a telemetry snapshot into the store under canonical keys.
extension TelemetryStoreIngest on TelemetryStore {
  /// Ingests a map of canonical key → value (see [TelemetryKey]).
  void ingest(Map<String, dynamic> snapshot) {
    snapshot.forEach(update);
  }
}

/// Maps the field names of a decoded `TelemetryValues` struct (from vesc_proto)
/// to canonical [TelemetryKey]s. The dashboard app uses this to translate a
/// decoded packet into a store snapshot without coupling the telemetry package
/// to vesc_proto.
const Map<String, String> kValuesKeyMap = <String, String>{
  'tempMosfet': TelemetryKey.tempMosfet,
  'tempMotor': TelemetryKey.tempMotor,
  'currentMotor': TelemetryKey.currentMotor,
  'currentInput': TelemetryKey.currentInput,
  'id': 'foc.id',
  'iq': 'foc.iq',
  'duty': TelemetryKey.duty,
  'erpm': TelemetryKey.erpm,
  'vIn': TelemetryKey.vIn,
  'ampHoursDischarged': TelemetryKey.ampHoursDischarged,
  'ampHoursCharged': TelemetryKey.ampHoursCharged,
  'wattHoursDischarged': TelemetryKey.wattHoursDischarged,
  'wattHoursCharged': TelemetryKey.wattHoursCharged,
  'tachometer': TelemetryKey.tachometer,
  'tachometerAbs': TelemetryKey.tachometerAbs,
  'fault': TelemetryKey.fault,
};
