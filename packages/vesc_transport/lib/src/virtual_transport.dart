/// An in-memory, pure-Dart VESC transport used by `vesc_sim` and tests.
///
/// A [VirtualTransportPair] creates two endpoints wired back-to-back: bytes
/// sent by one are framed and delivered (unframed) to the other. This lets the
/// dashboard runtime and the simulator talk over a virtual link with no
/// platform dependencies.

import 'dart:async';
import 'dart:developer';

import 'transport.dart';

/// Two [VirtualTransport] endpoints connected to each other.
class VirtualTransportPair {
  final VirtualTransport a;
  final VirtualTransport b;

  VirtualTransportPair._(this.a, this.b);

  factory VirtualTransportPair() {
    final aToB = StreamController<List<int>>.broadcast(sync: true);
    final bToA = StreamController<List<int>>.broadcast(sync: true);
    return VirtualTransportPair._(
      VirtualTransport._(aToB.sink, bToA.stream),
      VirtualTransport._(bToA.sink, aToB.stream),
    );
  }

  void close() {
    a.close();
    b.close();
  }
}

/// A [Transport] backed by an in-memory stream/sink pair. Each endpoint frames
/// outgoing payloads and decodes incoming frames.
class VirtualTransport extends FramedTransport {
  final StreamSink<List<int>> _sink;
  final Stream<List<int>> _incoming;
  StreamSubscription<List<int>>? _sub;

  VirtualTransport._(this._sink, this._incoming);

  @override
  Future<void> connect() async {
    if (state != TransportState.disconnected) return;
    setState(TransportState.connecting);
    _sub = _incoming.listen(feedRaw, onError: (Object error, StackTrace stack) {
      decoder.reset();
      log('VirtualTransport feedRaw error: $error',
          error: error, stackTrace: stack);
    });
    setState(TransportState.connected);
  }

  @override
  void rawSend(List<int> frameBytes) => _sink.add(frameBytes);

  @override
  Future<void> disconnect() async {
    setState(TransportState.disconnected);
    await _sub?.cancel();
    _sub = null;
  }

  void close() {
    _sub?.cancel();
    _sub = null;
    disposeFramed();
  }
}
