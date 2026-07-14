import 'package:test/test.dart';
import 'package:vesc_proto/vesc_proto.dart';

void main() {
  group('crc16', () {
    test('known vector for "123456789"', () {
      // CRC-16/XMODEM (poly 0x1021, init 0x0000) of ASCII "123456789".
      expect(crc16('123456789'.codeUnits), 0x31C3);
    });

    test('empty payload yields 0', () {
      expect(crc16([]), 0);
    });

    test('single byte 0x00', () {
      // 0x00 -> crc 0x0000 ... actually 0x00<<8=0, all shifts leave 0.
      expect(crc16([0x00]), 0x0000);
    });
  });

  group('encodeFrame / FrameDecoder', () {
    test('short frame round-trips a small payload', () {
      final payload = [0x00, 0x01, 0x02, 0x03];
      final frame = encodeFrame(payload);
      // [0x02][len=4][payload][crcHi][crcLo][0x03]
      expect(frame.first, kStartByteShort);
      expect(frame[1], 4);
      expect(frame.last, kStopByte);
      expect(frame.length, 1 + 1 + 4 + 2 + 1);

      final dec = FrameDecoder()..add(frame);
      expect(dec.payloads, hasLength(1));
      expect(dec.payloads.single, payload);
    });

    test('long frame is used for payloads >= 256 bytes', () {
      final payload = List<int>.generate(256, (i) => i & 0xFF);
      final frame = encodeFrame(payload);
      expect(frame.first, kStartByteLong);
      expect(frame[1], 0x01); // length high
      expect(frame[2], 0x00); // length low (256)
      expect(frame.last, kStopByte);

      final dec = FrameDecoder()..add(frame);
      expect(dec.payloads, hasLength(1));
      expect(dec.payloads.single, payload);
    });

    test('rejects frame with corrupted payload (CRC mismatch)', () {
      final payload = [0x00, 0x01, 0x02, 0x03];
      final frame = encodeFrame(payload);
      // Flip a payload byte.
      frame[2] ^= 0xFF;
      expect(() => FrameDecoder().add(frame), throwsA(isA<FrameException>()));
    });

    test('splits a stream into multiple payloads (byte-at-a-time)', () {
      final a = [0x00, 0x01];
      final b = [0x02, 0x03, 0x04];
      final combined = [...encodeFrame(a), ...encodeFrame(b)];
      final dec = FrameDecoder();
      for (final byte in combined) {
        dec.add([byte]);
      }
      expect(dec.payloads, hasLength(2));
      expect(dec.payloads[0], a);
      expect(dec.payloads[1], b);
    });

    test('skips noise bytes before a start byte', () {
      final payload = [0x05, 0x06];
      final dec = FrameDecoder()..add([0xFF, 0xEE, ...encodeFrame(payload)]);
      expect(dec.payloads, hasLength(1));
      expect(dec.payloads.single, payload);
    });

    test('empty payload round-trips', () {
      final frame = encodeFrame([]);
      // [0x02][0x00][crcHi][crcLo][0x03]
      expect(frame.length, 1 + 1 + 0 + 2 + 1);
      final dec = FrameDecoder()..add(frame);
      expect(dec.payloads, hasLength(1));
      expect(dec.payloads.single, isEmpty);
    });
  });
}
