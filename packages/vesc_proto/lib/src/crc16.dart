/// CRC-16/CCITT used by the VESC serial protocol.
///
/// Polynomial: 0x1021, initial value: 0x0000, no reflection (MSB-first),
/// no final XOR. This matches `crc16` in the VESC firmware.
library;

/// Computes the VESC CRC-16 over [bytes].
int crc16(List<int> bytes) {
  var crc = 0;
  for (final b in bytes) {
    crc ^= b << 8;
    for (var i = 0; i < 8; i++) {
      if ((crc & 0x8000) != 0) {
        crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
      } else {
        crc = (crc << 1) & 0xFFFF;
      }
    }
  }
  return crc & 0xFFFF;
}
