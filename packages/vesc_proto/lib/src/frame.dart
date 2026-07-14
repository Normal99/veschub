/// VESC UART frame codec.
///
/// Wire format (matches the VESC bldc `packet.c` state machine):
///
///  * Short packet (payload length 0..255):
///    `[0x02][len][payload...][crcHi][crcLo][0x03]`
///  * Long packet (payload length 256..65535):
///    `[0x03][lenHi][lenLo][payload...][crcHi][crcLo][0x03]`
///
/// The CRC-16 (see [crc16]) is computed over the payload only and appended
/// big-endian. The stop byte is always `0x03`.
library;

import 'crc16.dart';

/// Start byte for a short frame (payload length < 256).
const int kStartByteShort = 0x02;

/// Start byte for a long frame (payload length 256..65535).
const int kStartByteLong = 0x03;

/// Stop byte terminating every frame.
const int kStopByte = 0x03;

/// Maximum payload length encodable in a long frame.
const int kMaxPayloadLength = 0xFFFF;

/// Encodes [payload] into a complete VESC frame (including start, CRC and stop bytes).
///
/// Automatically selects the short or long frame form based on the payload length.
List<int> encodeFrame(List<int> payload) {
  final len = payload.length;
  if (len > kMaxPayloadLength) {
    throw ArgumentError.value(
      len,
      'payload length',
      'Must be <= $kMaxPayloadLength',
    );
  }

  final crc = crc16(payload);
  final crcHi = (crc >> 8) & 0xFF;
  final crcLo = crc & 0xFF;

  final out = <int>[];
  if (len < 256) {
    out
      ..add(kStartByteShort)
      ..add(len);
  } else {
    out
      ..add(kStartByteLong)
      ..add((len >> 8) & 0xFF)
      ..add(len & 0xFF);
  }
  out.addAll(payload);
  out
    ..add(crcHi)
    ..add(crcLo)
    ..add(kStopByte);
  return out;
}

/// Thrown by [FrameDecoder] when a frame is malformed (bad CRC, unexpected byte,
/// length overruns, etc.).
class FrameException implements Exception {
  final String message;
  FrameException(this.message);
  @override
  String toString() => 'FrameException: $message';
}

/// A stateful, streaming VESC frame decoder.
///
/// Feed it bytes with [add]; every complete, CRC-verified frame yields its
/// payload via the returned list (also available via [payloads]). Bytes that do
/// not belong to a valid frame are skipped until a start byte is seen, so the
/// decoder self-synchronises on a noisy stream.
class FrameDecoder {
  final List<List<int>> payloads = [];

  _FrameState _state = _FrameState.idle;
  bool _isLong = false;
  int _lenHigh = 0;
  int _lengthRemaining = 0;
  final List<int> _payload = [];
  int _crcHi = 0;
  int _crcExpected = 0;

  /// Processes [bytes] and appends any complete payloads to [payloads].
  void add(List<int> bytes) {
    for (final b in bytes) {
      _feed(b & 0xFF);
    }
  }

  /// Clears any in-progress frame and previously decoded payloads.
  void reset() {
    _state = _FrameState.idle;
    _isLong = false;
    _lengthRemaining = 0;
    _payload.clear();
    payloads.clear();
  }

  void _feed(int b) {
    switch (_state) {
      case _FrameState.idle:
        if (b == kStartByteShort) {
          _beginFrame(isLong: false);
        } else if (b == kStartByteLong) {
          _beginFrame(isLong: true);
        }
      // Otherwise: stay idle, skip noise.

      case _FrameState.len:
        if (_isLong) {
          _lenHigh = b;
          _state = _FrameState.lenLow;
        } else {
          _startPayload(b);
        }

      case _FrameState.lenLow:
        _startPayload((_lenHigh << 8) | b);

      case _FrameState.payload:
        _payload.add(b);
        _lengthRemaining--;
        if (_lengthRemaining == 0) {
          _state = _FrameState.crcHi;
        }

      case _FrameState.crcHi:
        _crcHi = b;
        _state = _FrameState.crcLo;

      case _FrameState.crcLo:
        _crcExpected = (_crcHi << 8) | b;
        _state = _FrameState.stop;

      case _FrameState.stop:
        if (b != kStopByte) {
          throw FrameException('Bad stop byte: 0x${b.toRadixString(16)}');
        }
        _complete();
    }
  }

  void _beginFrame({required bool isLong}) {
    _isLong = isLong;
    _payload.clear();
    _state = _FrameState.len;
  }

  void _startPayload(int length) {
    if (length > kMaxPayloadLength) {
      throw FrameException('Payload length too large: $length');
    }
    _lengthRemaining = length;
    _state = length == 0 ? _FrameState.crcHi : _FrameState.payload;
  }

  void _complete() {
    final actual = crc16(_payload);
    if (actual != _crcExpected) {
      throw FrameException(
          'CRC mismatch: expected 0x${_crcExpected.toRadixString(16)}, '
          'got 0x${actual.toRadixString(16)}');
    }
    payloads.add(List<int>.unmodifiable(_payload));
    _state = _FrameState.idle;
  }
}

enum _FrameState { idle, len, lenLow, payload, crcHi, crcLo, stop }
