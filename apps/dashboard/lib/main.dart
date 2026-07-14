/// Veschub Dashboard — the runtime app.
///
/// In dev/debug this viewer is wired to a [VescSim] over an in-memory
/// [VirtualTransportPair], so the full decode → bind → render pipeline runs
/// with no hardware. Swap in a BLE transport (flutter_blue_plus) to validate
/// against a real VESC — the runtime + widget layer is identical. First-run
/// onboarding and persisted settings gate the experience.
library;

import 'dart:async';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_sim/vesc_sim.dart';
import 'package:vesc_transport/vesc_transport.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import 'onboarding/dashboard_onboarding.dart';
import 'providers/settings_provider.dart';
import 'settings/dashboard_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DashboardApp()));
}

class DashboardApp extends ConsumerWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);

    final themeMode = switch (settings.themeMode) {
      ThemePreference.system => ThemeMode.system,
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
    };
    return MaterialApp(
      title: 'Veschub Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: themeMode,
      home: settings.onboardingDone
          ? const ViewerScreen()
          : DashboardOnboarding(
              onDone: () => settings.markOnboardingDone(),
            ),
      routes: {
        '/settings': (_) => const DashboardSettingsScreen(),
      },
    );
  }
}

/// A sample dashboard authored against canonical telemetry keys. In a real
/// flow this document is loaded from drift storage (Phase 3); here it's baked
/// in to validate the runtime against the sim.
const _sampleDocument = DashboardDocument(
  name: 'Sim viewer',
  canvas: CanvasSize(width: 800, height: 480),
  background: 0xFF000000,
  accent: 0xFFE0E0E0,
  widgets: [
    WidgetInstance(
      id: 'rpm',
      kind: 'gauge',
      transform: [1, 0, 0, 1, 40, 40],
      properties: {
        'value': Binding.telemetry(key: 'erpm'),
        'min': Binding.literal(value: -30000),
        'max': Binding.literal(value: 30000),
        'label': Binding.literal(value: 'RPM'),
        'color': Binding.literal(value: 0xFF4FC3F7),
      },
    ),
    WidgetInstance(
      id: 'duty',
      kind: 'bar',
      transform: [1, 0, 0, 1, 360, 40],
      properties: {
        'value': Binding.telemetry(key: 'duty'),
        'min': Binding.literal(value: 0),
        'max': Binding.literal(value: 1),
        'label': Binding.literal(value: 'Duty'),
        'color': Binding.literal(value: 0xFFFFB74D),
      },
    ),
    WidgetInstance(
      id: 'vIn',
      kind: 'text',
      transform: [1, 0, 0, 1, 40, 320],
      properties: {
        'value': Binding.telemetry(key: 'v_in'),
        'label': Binding.literal(value: 'Pack voltage'),
        'unit': Binding.literal(value: 'V'),
        'color': Binding.literal(value: 0xFFAED581),
      },
    ),
    WidgetInstance(
      id: 'temp',
      kind: 'text',
      transform: [1, 0, 0, 1, 360, 320],
      properties: {
        'value': Binding.telemetry(key: 'temp.mosfet'),
        'label': Binding.literal(value: 'MOSFET'),
        'unit': Binding.literal(value: '°C'),
        'color': Binding.literal(value: 0xFFEF5350),
      },
    ),
  ],
);

class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key});

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late final TelemetryStore _store;
  late final DashboardRuntime _runtime;
  late final VirtualTransportPair _pair;
  late final VescSim _sim;
  late final StreamSubscription<List<int>> _rxSub;
  late final StreamSubscription<Map<String, ResolvedProperties>> _dirtySub;

  final Map<String, ResolvedProperties> _resolved = {};
  TransportState _linkState = TransportState.disconnected;

  @override
  void initState() {
    super.initState();
    _store = TelemetryStore();
    _runtime = DashboardRuntime(document: _sampleDocument, store: _store);

    // Wire a mock VESC over a virtual transport.
    _pair = VirtualTransportPair();
    _sim = VescSim(_pair.a);

    _pair.b.stateChanges.listen((s) {
      if (mounted) setState(() => _linkState = s);
    });

    _rxSub = _pair.b.payloads.listen(_onPayload);
    _dirtySub = _runtime.dirtyWidgets.listen((dirty) {
      if (!mounted) return;
      setState(() {
        for (final entry in dirty.entries) {
          _resolved[entry.key] = entry.value;
        }
      });
    });

    _pair.b.connect().then((_) => _sim.clientTransport.connect()).then((_) {
      _sim.start();
      _runtime.start();
    });
  }

  void _onPayload(List<int> payload) {
    try {
      final v = TelemetryValues.fromPayload(payload);
      _store.ingest({
        TelemetryKey.erpm: v.erpm,
        TelemetryKey.duty: v.duty,
        TelemetryKey.vIn: v.vIn,
        TelemetryKey.tempMosfet: v.tempMosfet,
        TelemetryKey.currentMotor: v.currentMotor,
        TelemetryKey.currentInput: v.currentInput,
      });
    } catch (_) {
      // Ignore non-telemetry payloads during Phase 2.
    }
  }

  @override
  void dispose() {
    _rxSub.cancel();
    _dirtySub.cancel();
    _runtime.dispose();
    _sim.stop();
    _pair.close();
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Veschub · Sim viewer',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _LinkBadge(state: _linkState),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: _sampleDocument.canvas.width,
            height: _sampleDocument.canvas.height,
            child: ColoredBox(
              color: Color(_sampleDocument.background),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final w in _sampleDocument.widgets) _positioned(w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _positioned(WidgetInstance w) {
    final tx = w.transform[4];
    final ty = w.transform[5];
    final resolved = _resolved[w.id] ?? const <String, dynamic>{};
    return Positioned(
      left: tx,
      top: ty,
      width: 300,
      height: 220,
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222222)),
          ),
          padding: const EdgeInsets.all(12),
          child: buildWidget(w, resolved),
        ),
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  final TransportState state;
  const _LinkBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      TransportState.connected => ('SIM ●', Colors.greenAccent),
      TransportState.connecting => ('connecting…', Colors.amberAccent),
      TransportState.error => ('error', Colors.redAccent),
      TransportState.disconnected => ('offline', Colors.white54),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
