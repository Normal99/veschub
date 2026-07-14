/// Veschub VESC protocol codec.
///
/// Encodes and decodes the VESC bldc serial (COMM) protocol: frame
/// serialisation, CRC-16, typed telemetry and control commands.
library;

export 'src/byte_io.dart';
export 'src/comm_packet_id.dart';
export 'src/commands.dart';
export 'src/crc16.dart';
export 'src/frame.dart';
export 'src/telemetry_values.dart';
