/// Veschub transport layer — connection abstraction over VESC links.
///
/// Provides a uniform [Transport] interface and VESC framing; ships a
/// pure-Dart [VirtualTransport] for simulation and tests. BLE and USB-serial
/// adapters wrap the same interface and live with the platform apps.
library;

export 'src/transport.dart';
export 'src/virtual_transport.dart';
