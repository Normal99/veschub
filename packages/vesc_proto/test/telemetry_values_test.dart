import 'package:test/test.dart';
import 'package:vesc_proto/vesc_proto.dart';

void main() {
  group('TelemetryValues', () {
    test('round-trips a known GET_VALUES payload in firmware field order', () {
      // Build a payload with ByteWriter using the firmware scales.
      final w = ByteWriter()
        ..writeU8(CommPacketId.getValues.code)
        ..writeI16((45.5 * 10).round()) // temp_fet = 45.5 C
        ..writeI16((55.0 * 10).round()) // temp_motor = 55.0 C
        ..writeI32((42.50 * 100).round()) // current_motor = 42.50 A
        ..writeI32((-12.0 * 100).round()) // current_in = -12.0 A
        ..writeI32((5.0 * 100).round()) // id = 5.0 A
        ..writeI32((-40.0 * 100).round()) // iq = -40.0 A
        ..writeI16((0.785 * 1000).round()) // duty = 0.785 (f16/1e3)
        ..writeI32(120000) // rpm
        ..writeU16((50.1 * 10).round()) // v_in = 50.1 V
        ..writeU32((65.4321 * 10000).round()) // ah discharged
        ..writeU32((12.3456 * 10000).round()) // ah charged
        ..writeU32((0.02 * 10000).round()) // wh discharged
        ..writeU32((0.01 * 10000).round()) // wh charged
        ..writeI32(-9999) // tachometer
        ..writeI32(9999) // tachometer_abs
        ..writeU8(1); // fault = overVoltage

      final v = TelemetryValues.fromPayload(w.bytes);
      expect(v.tempMosfet, closeTo(45.5, 1e-9));
      expect(v.tempMotor, closeTo(55.0, 1e-9));
      expect(v.currentMotor, closeTo(42.50, 1e-9));
      expect(v.currentInput, closeTo(-12.0, 1e-9));
      expect(v.id, closeTo(5.0, 1e-9));
      expect(v.iq, closeTo(-40.0, 1e-9));
      expect(v.duty, closeTo(0.785, 1e-9));
      expect(v.erpm, 120000);
      expect(v.vIn, closeTo(50.1, 1e-9));
      expect(v.ampHoursDischarged, closeTo(65.4321, 1e-9));
      expect(v.ampHoursCharged, closeTo(12.3456, 1e-9));
      expect(v.wattHoursDischarged, closeTo(0.02, 1e-9));
      expect(v.wattHoursCharged, closeTo(0.01, 1e-9));
      expect(v.tachometer, -9999);
      expect(v.tachometerAbs, 9999);
      expect(v.fault, FaultCode.overVoltage);
    });

    test('rejects a non-GET_VALUES payload', () {
      final w = ByteWriter()..writeU8(CommPacketId.setRpm.code);
      expect(() => TelemetryValues.fromPayload(w.bytes), throwsStateError);
    });
  });

  group('FirmwareVersion', () {
    test('decodes major/minor/hardware', () {
      final w = ByteWriter()
        ..writeU8(CommPacketId.getFirmwareVersion.code)
        ..writeU16(6)
        ..writeU16(2)
        ..writeCString('VESC HD60');

      final fw = FirmwareVersion.fromPayload(w.bytes);
      expect(fw.major, 6);
      expect(fw.minor, 2);
      expect(fw.hardwareName, 'VESC HD60');
    });
  });

  group('commands', () {
    test('encodeSetDuty scales by 100000 (firmware: int32/1e5)', () {
      final p = encodeSetDuty(0.5);
      expect(p[0], CommPacketId.setDuty.code);
      // (0.5 * 100000) = 50000 as int32 big-endian
      expect(p.sublist(1), [0x00, 0x00, 0xC3, 0x50]);
    });

    test('encodeSetRpm packs erpm as int32', () {
      final p = encodeSetRpm(1000);
      expect(p[0], CommPacketId.setRpm.code);
      final r = ByteReader(p)..readU8();
      expect(r.readI32(), 1000);
    });

    test('encodeSetCurrent scales by 1000 (firmware: int32/1e3)', () {
      final p = encodeSetCurrent(5.0);
      final r = ByteReader(p)..readU8();
      expect(r.readI32(), 5000);
    });

    test('encodeSetCurrentBrake encodes negative amps', () {
      final p = encodeSetCurrentBrake(-5.0);
      final r = ByteReader(p)..readU8();
      expect(r.readI32(), -5000);
    });
  });
}
