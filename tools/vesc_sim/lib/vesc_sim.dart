/// A mock VESC controller that emits telemetry and answers control commands
/// over a [VirtualTransport]. Drives Phase 1 hardware-free development.
library;

import 'dart:async';
import 'dart:math';

import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_transport/vesc_transport.dart';

/// Configuration for the simulated motor controller.
class VescSimConfig {
  final double nominalVoltage;
  final double maxRpm;
  final int motorPoles;
  final Duration tickInterval;
  final bool sineMotion;

  const VescSimConfig({
    this.nominalVoltage = 50.0,
    this.maxRpm = 30000,
    this.motorPoles = 14,
    this.tickInterval = const Duration(milliseconds: 100),
    this.sineMotion = true,
  });
}

/// Simulated VESC. Holds internal state (erpm, duty, current, voltage) and,
/// when [start]ed, periodically emits `COMM_GET_VALUES` payloads to the linked
/// transport's other endpoint.
class VescSim {
  final VescSimConfig config;
  final VirtualTransport _link;

  Timer? _timer;
  StreamSubscription<List<int>>? _rxSub;
  DateTime _t0 = DateTime.now();

  double _erpm = 0;
  double _duty = 0;
  double _currentMotor = 0;
  double _currentInput = 0;
  final double _vIn;
  final double _tempMosfet = 35.0;
  final double _tempMotor = 40.0;
  double _ampHoursDischarged = 0;
  double _wattHoursDischarged = 0;
  double _targetDuty = 0;

  VescSim(this._link, {this.config = const VescSimConfig()})
      : _vIn = config.nominalVoltage;

  /// The transport endpoint a client (dashboard) should connect to.
  ///
  /// The [VescSim] owns the other side of an internal
  /// [VirtualTransportPair]; callers wire [clientTransport] into their runtime.
  VirtualTransport get clientTransport => _link;

  /// Starts emitting telemetry and listening for commands.
  void start() {
    _t0 = DateTime.now();
    _rxSub = _link.payloads.listen(_onPayload);
    _timer = Timer.periodic(config.tickInterval, (_) => _emit());
  }

  /// Stops the simulator.
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _rxSub?.cancel();
    _rxSub = null;
  }

  void _onPayload(List<int> payload) {
    if (payload.isEmpty) return;
    final id = payload[0];
    switch (CommPacketId.fromCode(id)) {
      case CommPacketId.setDuty:
        final r = ByteReader(payload)..readU8();
        _targetDuty = r.readI32() / 100000.0;
        break;
      case CommPacketId.setCurrent:
        final r = ByteReader(payload)..readU8();
        _currentMotor = r.readI32() / 1000.0;
        break;
      case CommPacketId.setRpm:
        // Simple model: requested erpm becomes the new target; duty follows.
        final r = ByteReader(payload)..readU8();
        _erpm = r.readI32().toDouble();
        _duty = (_erpm / config.maxRpm).clamp(-1.0, 1.0).toDouble();
        break;
      default:
        // Unhandled command types are ignored in this Phase-1 sim.
        break;
    }
  }

  void _emit() {
    final elapsed = DateTime.now().difference(_t0).inMilliseconds / 1000.0;
    if (config.sineMotion) {
      // Drift erpm/duty in a sine so charts look alive even with no commands.
      final base = sin(elapsed * 0.6) * config.maxRpm * 0.6;
      _erpm = _erpm * 0.7 + base * 0.3;
      _duty = (_erpm / config.maxRpm).clamp(-1.0, 1.0).toDouble();
      _currentMotor = 30 * sin(elapsed * 1.1);
    } else {
      _duty += (_targetDuty - _duty) * 0.2;
      _erpm = _duty * config.maxRpm;
    }

    _currentInput = _currentMotor * _duty.abs();
    _ampHoursDischarged +=
        (_currentInput.abs() * config.tickInterval.inMilliseconds) /
            (1000.0 * 3600.0);
    _wattHoursDischarged +=
        (_currentInput.abs() * _vIn * config.tickInterval.inMilliseconds) /
            (1000.0 * 3600.0);

    final w = ByteWriter()
      ..writeU8(CommPacketId.getValues.code)
      // Field order + scales mirror VESC firmware COMM_GET_VALUES.
      ..writeI16((_tempMosfet * 10).round()) // temp_fet / 1e1
      ..writeI16((_tempMotor * 10).round()) // temp_motor / 1e1
      ..writeI32((_currentMotor * 100).round()) // current_motor / 1e2
      ..writeI32((_currentInput * 100).round()) // current_in / 1e2
      ..writeI32(0) // id / 1e2
      ..writeI32(0) // iq / 1e2
      ..writeI16((_duty * 1000).round()) // duty / 1e3
      ..writeI32(_erpm.round()) // rpm / 1e0
      ..writeU16((_vIn * 10).round()) // v_in / 1e1
      ..writeU32((_ampHoursDischarged * 10000).round()) // ah / 1e4
      ..writeU32(0) // ah_charged / 1e4
      ..writeU32((_wattHoursDischarged * 10000).round()) // wh / 1e4
      ..writeU32(0) // wh_charged / 1e4
      ..writeI32(_erpm.round()) // tachometer
      ..writeI32(_erpm.abs().round()) // tachometer_abs
      ..writeU8(0); // fault

    _link.send(w.bytes);
  }
}
