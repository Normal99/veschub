import 'dart:async';

import 'package:vesc_proto/vesc_proto.dart';

/// Connection state of a [Transport].
enum TransportState { disconnected, connecting, connected, error }

/// A byte-level transport that emits decoded VESC payloads and accepts
/// payloads to send.
///
/// Implementations: [VirtualTransport] (in-memory, for sim/tests), and the
/// BLE / USB-serial adapters in the dashboard app (built on `flutter_blue_plus`
/// and `flutter_libserialport`). The framing (start/stop/CRC) is handled
/// centrally by [FramedTransport].
abstract class Transport {
  TransportState get state;

  /// A broadcast stream of complete, CRC-verified payloads received from the
  /// remote VESC.
  Stream<List<int>> get payloads;

  /// Stream of [TransportState] transitions.
  Stream<TransportState> get stateChanges;

  /// Begins connecting. Resolves when the connection is established or throws.
  Future<void> connect();

  /// Sends a payload (the implementation frames it as needed).
  void send(List<int> payload);

  /// Gracefully disconnects.
  Future<void> disconnect();
}

/// Base class that adds VESC framing on top of a raw bidirectional byte pipe.
///
/// Subclasses implement [rawSend] (write frame bytes to the link) and call
/// [feedRaw] for every incoming chunk; this class handles [encodeFrame] and
/// [FrameDecoder] and exposes framed [payloads] and [send].
abstract class FramedTransport extends Transport {
  final FrameDecoder decoder = FrameDecoder();
  final StreamController<List<int>> _payloadController =
      StreamController<List<int>>.broadcast(sync: true);

  TransportState _state = TransportState.disconnected;
  final StreamController<TransportState> _stateController =
      StreamController<TransportState>.broadcast(sync: true);

  @override
  Stream<List<int>> get payloads => _payloadController.stream;

  @override
  Stream<TransportState> get stateChanges => _stateController.stream;

  @override
  TransportState get state => _state;

  /// Subclass hook: writes raw frame bytes to the underlying link.
  void rawSend(List<int> frameBytes);

  /// Subclasses call this for every chunk of bytes arriving from the link.
  void feedRaw(List<int> bytes) {
    decoder.add(bytes);
    for (final p in decoder.payloads) {
      _payloadController.add(p);
    }
    decoder.payloads.clear();
  }

  @override
  void send(List<int> payload) => rawSend(encodeFrame(payload));

  /// Subclasses call this to transition [state] and broadcast it.
  void setState(TransportState next) {
    _state = next;
    _stateController.add(next);
  }

  /// Releases framing resources. Subclasses must call this from [disconnect].
  void disposeFramed() {
    decoder.reset();
    _payloadController.close();
    _stateController.close();
  }
}
