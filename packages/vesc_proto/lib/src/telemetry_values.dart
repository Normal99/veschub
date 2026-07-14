/// Typed telemetry payload decoders for VESC COMM packets.
///
/// Field order and scales mirror the VESC bldc firmware `commands.c`
/// `COMM_GET_VALUES` handler (the mask-bit layout), so frames captured from a
/// real controller over BLE decode identically here.
///
/// Scales (see `buffer_append_float16/32` calls in the firmware):
///  * `tempMosfet`     — °C    (float16 / 1e1)
///  * `tempMotor`      — °C    (float16 / 1e1)
///  * `currentMotor`   — A     (float32 / 1e2)
///  * `currentInput`   — A     (float32 / 1e2)
///  * `id`             — A     (float32 / 1e2, FOC d-axis current)
///  * `iq`             — A     (float32 / 1e2, FOC q-axis current)
///  * `duty`           — ratio (float16 / 1e3, -1.0..1.0)
///  * `erpm`          — eRPM  (float32 / 1e0)
///  * `vIn`           — V     (float16 / 1e1)
///  * `ampHoursDischarged`  — Ah (float32 / 1e4)
///  * `ampHoursCharged`     — Ah (float32 / 1e4)
///  * `wattHoursDischarged` — Wh (float32 / 1e4)
///  * `wattHoursCharged`    — Wh (float32 / 1e4)
///  * `tachometer`    — counts (int32)
///  * `tachometerAbs` — counts (int32)
///  * `fault`         — [FaultCode] (uint8)
library;

import 'byte_io.dart';
import 'comm_packet_id.dart';

/// Motor controller fault codes (subset of VESC `mc_fault_code`).
enum FaultCode {
  none(0),
  overVoltage(1),
  underVoltage(2),
  drv(3),
  absOverCurrent(4),
  overTempFet(5),
  overTempMotor(6),
  gateDriverOverTemp(7),
  faultResBoot(8),
  faultResSwitch(9),
  faultResFwdBrake(10),
  faultResStop(11),
  faultRes(12);

  final int code;
  const FaultCode(this.code);

  static FaultCode fromCode(int code) => FaultCode.values.firstWhere(
        (e) => e.code == code,
        orElse: () => FaultCode.none,
      );
}

/// Decoded `COMM_GET_VALUES` (packet id 0) payload, in firmware field order.
class TelemetryValues {
  final double tempMosfet;
  final double tempMotor;
  final double currentMotor;
  final double currentInput;
  final double id;
  final double iq;
  final double duty;
  final int erpm;
  final double vIn;
  final double ampHoursDischarged;
  final double ampHoursCharged;
  final double wattHoursDischarged;
  final double wattHoursCharged;
  final int tachometer;
  final int tachometerAbs;
  final FaultCode fault;

  const TelemetryValues({
    required this.tempMosfet,
    required this.tempMotor,
    required this.currentMotor,
    required this.currentInput,
    required this.id,
    required this.iq,
    required this.duty,
    required this.erpm,
    required this.vIn,
    required this.ampHoursDischarged,
    required this.ampHoursCharged,
    required this.wattHoursDischarged,
    required this.wattHoursCharged,
    required this.tachometer,
    required this.tachometerAbs,
    required this.fault,
  });

  /// Decodes a full `COMM_GET_VALUES` payload (including the leading packet-id byte).
  factory TelemetryValues.fromPayload(List<int> payload) {
    final r = ByteReader(payload);
    final packetId = r.readU8();
    if (packetId != CommPacketId.getValues.code) {
      throw StateError('Not a COMM_GET_VALUES payload (id=$packetId, '
          'expected ${CommPacketId.getValues.code})');
    }
    return decodeFromAfterId(r);
  }

  /// Decodes the values fields assuming the cursor is positioned *after* the
  /// packet-id byte (the full, non-selective layout — all mask bits present).
  static TelemetryValues decodeFromAfterId(ByteReader r) {
    return TelemetryValues(
      tempMosfet: r.readI16() / 10.0,
      tempMotor: r.readI16() / 10.0,
      currentMotor: r.readI32() / 100.0,
      currentInput: r.readI32() / 100.0,
      id: r.readI32() / 100.0,
      iq: r.readI32() / 100.0,
      duty: r.readI16() / 1000.0,
      erpm: r.readI32(),
      vIn: r.readU16() / 10.0,
      ampHoursDischarged: r.readU32() / 10000.0,
      ampHoursCharged: r.readU32() / 10000.0,
      wattHoursDischarged: r.readU32() / 10000.0,
      wattHoursCharged: r.readU32() / 10000.0,
      tachometer: r.readI32(),
      tachometerAbs: r.readI32(),
      fault: FaultCode.fromCode(r.readU8()),
    );
  }

  @override
  String toString() =>
      'TelemetryValues(erpm: $erpm, duty: $duty, vIn: $vIn, currentMotor: $currentMotor, '
      'currentInput: $currentInput, tempMosfet: $tempMosfet, fault: $fault)';
}

/// Decoded `COMM_GET_FIRMWARE_VERSION` (packet id 24) payload.
///
/// Firmware-version responses have grown across VESC releases; this decoder
/// reads the stable prefix (major, minor, HW name) and leaves the remainder
/// (UUID, pairing flag, test version, hw type, …) available via [ByteReader].
class FirmwareVersion {
  final int major;
  final int minor;
  final String hardwareName;

  const FirmwareVersion({
    required this.major,
    required this.minor,
    required this.hardwareName,
  });

  factory FirmwareVersion.fromPayload(List<int> payload) {
    final r = ByteReader(payload);
    final id = r.readU8();
    if (id != CommPacketId.getFirmwareVersion.code) {
      throw StateError('Not a firmware-version payload (id=$id)');
    }
    final major = r.readU16();
    final minor = r.readU16();
    final hw = r.readCString();
    return FirmwareVersion(major: major, minor: minor, hardwareName: hw);
  }

  @override
  String toString() => 'FirmwareVersion($major.$minor, hw: $hardwareName)';
}
