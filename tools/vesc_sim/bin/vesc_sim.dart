import 'dart:async';
import 'dart:io';

import 'package:vesc_sim/vesc_sim.dart';
import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_transport/vesc_transport.dart';

/// Runs the mock VESC over a virtual transport, emitting telemetry at 10 Hz.
///
/// Usage:
///   dart run tools/vesc_sim/bin/vesc_sim.dart
///
/// In Phase 1 this is a no-op process loop: it spins the sim so the dashboard
/// app (in a separate process or via a shared virtual transport in tests) can
/// decode its frames. A socket/serial bridge will be added when the dashboard
/// app is wired up in Phase 2.
Future<void> main(List<String> args) async {
  final pair = VirtualTransportPair();
  final sim = VescSim(
    pair.a,
    config: const VescSimConfig(tickInterval: Duration(milliseconds: 100)),
  );

  await pair.b.connect();
  await sim.clientTransport.connect();
  sim.start();

  // Print decoded telemetry to stdout as a smoke check.
  final sub = pair.b.payloads.listen((payload) {
    try {
      final v = TelemetryValues.fromPayload(payload);
      print('[vesc_sim] erpm=${v.erpm} duty=${v.duty.toStringAsFixed(3)} '
          'vIn=${v.vIn.toStringAsFixed(2)} current=${v.currentMotor.toStringAsFixed(2)}A');
    } catch (_) {
      // Ignore non-telemetry payloads.
    }
  });

  print('vesc_sim running — press Ctrl-C to stop.');
  final done = Completer<void>();
  ProcessSignal.sigint.watch().listen((_) {
    if (!done.isCompleted) done.complete();
  });
  await done.future;
  await sub.cancel();
  await sim.stop();
  pair.close();
  print('vesc_sim stopped.');
}
