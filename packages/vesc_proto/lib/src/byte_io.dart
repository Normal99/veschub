/// Big-endian byte reader over an unmodifiable byte sequence with a moving cursor.
library;

import 'dart:typed_data';

/// A cursor-based reader over [bytes] using big-endian (network) order, as used
/// by the VESC protocol.
class ByteReader {
  final List<int> bytes;
  int offset = 0;

  ByteReader(this.bytes);

  /// Creates a reader starting at [start].
  ByteReader.from(this.bytes, [this.offset = 0]);

  int get remaining => bytes.length - offset;
  bool get isAtEnd => offset >= bytes.length;

  int readU8() {
    _require(1);
    return bytes[offset++];
  }

  int readU16() {
    _require(2);
    final v = (bytes[offset] << 8) | bytes[offset + 1];
    offset += 2;
    return v;
  }

  int readU32() {
    _require(4);
    final v = (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    offset += 4;
    return v;
  }

  int readI16() {
    final raw = readU16();
    return raw >= 0x8000 ? raw - 0x10000 : raw;
  }

  int readI32() {
    final raw = readU32();
    return raw >= 0x80000000 ? raw - 0x100000000 : raw;
  }

  /// Reads a NUL-terminated ASCII/UTF-8 string.
  String readCString() {
    final start = offset;
    while (offset < bytes.length && bytes[offset] != 0) {
      offset++;
    }
    final str = String.fromCharCodes(bytes.sublist(start, offset));
    if (offset < bytes.length) offset++; // consume the NUL
    return str;
  }

  /// Reads [length] raw bytes as a new list.
  Uint8List readBytes(int length) {
    _require(length);
    final out = Uint8List.fromList(bytes.sublist(offset, offset + length));
    offset += length;
    return out;
  }

  void _require(int n) {
    if (bytes.length - offset < n) {
      throw RangeError(
        'Not enough bytes: need $n, have ${bytes.length - offset}',
      );
    }
  }
}

/// Writes values to a growable byte buffer in big-endian order.
class ByteWriter {
  final List<int> _buf = [];

  List<int> get bytes => List.unmodifiable(_buf);

  void writeU8(int v) => _buf.add(v & 0xFF);
  void writeU16(int v) => _buf
    ..add((v >> 8) & 0xFF)
    ..add(v & 0xFF);
  void writeU32(int v) => _buf
    ..add((v >> 24) & 0xFF)
    ..add((v >> 16) & 0xFF)
    ..add((v >> 8) & 0xFF)
    ..add(v & 0xFF);

  void writeI16(int v) => writeU16(v < 0 ? v + 0x10000 : v);
  void writeI32(int v) => writeU32(v < 0 ? v + 0x100000000 : v);

  void writeCString(String s) {
    _buf.addAll(s.codeUnits);
    _buf.add(0);
  }

  void addAll(List<int> data) => _buf.addAll(data);
}
