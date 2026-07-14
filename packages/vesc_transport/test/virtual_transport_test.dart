import 'dart:async';

import 'package:test/test.dart';
import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_transport/vesc_transport.dart';

void main() {
  group('VirtualTransportPair', () {
    test('delivers framed payloads both ways', () async {
      final pair = VirtualTransportPair();
      await pair.a.connect();
      await pair.b.connect();

      final received = <List<int>>[];
      pair.b.payloads.listen(received.add);

      pair.a.send([0x00, 0x01, 0x02]);
      await Future<void>.delayed(Duration.zero);

      expect(received, [
        [0x00, 0x01, 0x02],
      ]);

      // Reverse direction.
      final receivedA = <List<int>>[];
      pair.a.payloads.listen(receivedA.add);
      pair.b.send([0x10, 0x20]);
      await Future<void>.delayed(Duration.zero);

      expect(receivedA, [
        [0x10, 0x20],
      ]);

      pair.close();
    });

    test('reports connection state transitions', () async {
      final pair = VirtualTransportPair();
      final states = <TransportState>[];
      pair.a.stateChanges.listen(states.add);

      await pair.a.connect();
      await pair.a.disconnect();

      expect(states, [
        TransportState.connecting,
        TransportState.connected,
        TransportState.disconnected,
      ]);
      pair.close();
    });

    test('round-trips a real telemetry payload via encode/decode', () async {
      final pair = VirtualTransportPair();
      await pair.a.connect();
      await pair.b.connect();

      // Simulate the controller emitting a GET_VALUES response (firmware order).
      final w = ByteWriter()
        ..writeU8(CommPacketId.getValues.code)
        ..writeI16((30.0 * 10).round()) // temp_fet
        ..writeI16((35.0 * 10).round()) // temp_motor
        ..writeI32(0) // current_motor
        ..writeI32(0) // current_in
        ..writeI32(0) // id
        ..writeI32(0) // iq
        ..writeI16((0.5 * 1000).round()) // duty = 0.5 (f16/1e3)
        ..writeI32(9000) // rpm
        ..writeU16((42.0 * 10).round()) // v_in
        ..writeU32(0) // ah
        ..writeU32(0) // ah charged
        ..writeU32(0) // wh
        ..writeU32(0) // wh charged
        ..writeI32(0) // tach
        ..writeI32(0) // tach abs
        ..writeU8(0); // fault

      final got = Completer<List<int>>();
      pair.b.payloads.listen(got.complete);

      pair.a.send(w.bytes);
      final payload = await got.future;
      final v = TelemetryValues.fromPayload(payload);
      expect(v.erpm, 9000);
      expect(v.duty, closeTo(0.5, 1e-9));
      expect(v.vIn, closeTo(42.0, 1e-9));

      pair.close();
    });
  });
}
