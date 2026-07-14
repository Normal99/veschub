/// Encoders for VESC control commands (set duty / current / RPM / brake).
library;

import 'byte_io.dart';
import 'comm_packet_id.dart';

/// Builds a `COMM_SET_DUTY` payload for a duty ratio in [-1.0, 1.0].
List<int> encodeSetDuty(double duty) {
  final w = ByteWriter()
    ..writeU8(CommPacketId.setDuty.code)
    ..writeI32((duty * 100000).round());
  return w.bytes;
}

/// Builds a `COMM_SET_CURRENT` payload for a current in amps.
List<int> encodeSetCurrent(double amps) {
  final w = ByteWriter()
    ..writeU8(CommPacketId.setCurrent.code)
    ..writeI32((amps * 1000).round());
  return w.bytes;
}

/// Builds a `COMM_SET_CURRENT_BRAKE` payload for a braking current in amps.
List<int> encodeSetCurrentBrake(double amps) {
  final w = ByteWriter()
    ..writeU8(CommPacketId.setCurrentBrake.code)
    ..writeI32((amps * 1000).round());
  return w.bytes;
}

/// Builds a `COMM_SET_RPM` payload for an electrical RPM target.
List<int> encodeSetRpm(int erpm) {
  final w = ByteWriter()
    ..writeU8(CommPacketId.setRpm.code)
    ..writeI32(erpm);
  return w.bytes;
}
