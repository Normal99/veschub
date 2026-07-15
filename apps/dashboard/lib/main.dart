/// Veschub Dashboard — the runtime app.
///
/// In dev/debug this viewer is wired to a [VescSim] over an in-memory
/// [VirtualTransportPair], so the full decode → bind → render pipeline runs
/// with no hardware. Real BLE/USB transport adapters are planned but not yet
/// implemented — see FUTURE_FEATURES.md. First-run onboarding and persisted
/// settings gate the experience.
library;

import 'dart:async';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:dashboard_storage/dashboard_storage.dart';
import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_sim/vesc_sim.dart';
import 'package:vesc_transport/vesc_transport.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import 'onboarding/dashboard_onboarding.dart';
import 'settings/dashboard_settings_screen.dart';

/// Singleton drift database (opened lazily).
final dashboardDatabaseProvider = Provider<DashboardDatabase>((ref) {
  final db = DashboardDatabase();
  ref.onDispose(db.close);
  return db;
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await createSettingsService();
  runApp(
    ProviderScope(
      overrides: [settingsServiceProvider.overrideWith((ref) => settings)],
      child: const DashboardApp(),
    ),
  );
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
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      themeMode: themeMode,
      home: settings.onboardingDone
          ? const ViewerScreen()
          : const DashboardOnboarding(),
      routes: {
        '/settings': (_) => const DashboardSettingsScreen(),
      },
    );
  }
}

/// A sample dashboard authored against canonical telemetry keys. Used as the
/// initial document so the viewer works out of the box; the user can open
/// other saved dashboards from storage via the toolbar.
DashboardDocument sampleDocument() => const DashboardDocument(
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

class ViewerScreen extends ConsumerStatefulWidget {
  const ViewerScreen({super.key});

  @override
  ConsumerState<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends ConsumerState<ViewerScreen> {
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
    _runtime = DashboardRuntime(document: sampleDocument(), store: _store);

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
      if (!mounted) return;
      _sim.start();
      _runtime.start();
    }).catchError((e) {
      if (mounted) {
        setState(() => _linkState = TransportState.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e')),
        );
      }
    });
  }

  void _loadDocument(DashboardDocument doc) {
    _runtime.setDocument(doc);
    _resolved.clear();
    setState(() {});
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
      // Ignore non-telemetry payloads.
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
    final doc = _runtime.document;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white70 : Colors.black87;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Veschub · ${doc.name}',
          style: TextStyle(color: fg, fontSize: 14),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: _LinkBadge(state: _linkState, fg: fg),
            ),
          ),
          IconButton(
            icon: Icon(Icons.folder_open, color: fg),
            onPressed: () => _showOpenDialog(context),
            tooltip: 'Open dashboard',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: fg),
            onPressed: () => Navigator.of(context).pushNamed('/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Center(
        child: FittedBox(
          child: SizedBox(
            width: doc.canvas.width,
            height: doc.canvas.height,
            child: ColoredBox(
              color: Color(doc.background),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final w in doc.widgets)
                    _positioned(w, key: ValueKey(w.id)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _positioned(WidgetInstance w, {Key? key}) {
    final tx = w.transform[4];
    final ty = w.transform[5];
    final resolved = _resolved[w.id] ?? const <String, dynamic>{};
    return Positioned(
      key: key,
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

  Future<void> _showOpenDialog(BuildContext context) async {
    final db = ref.read(dashboardDatabaseProvider);
    final entries = await db.recentDashboards();
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open dashboard'),
          content: SizedBox(
            width: 400,
            child: entries.isEmpty
                ? const Text('No saved dashboards yet. Author one in Studio.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: Text(e.name),
                        subtitle: Text('Updated ${e.updatedAt.toLocal()}'),
                        onTap: () {
                          final doc = db.decodeDocument(e);
                          _loadDocument(doc);
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _loadDocument(sampleDocument());
                Navigator.of(context).pop();
              },
              child: const Text('Load sample'),
            ),
          ],
        );
      },
    );
  }
}

class _LinkBadge extends StatelessWidget {
  final TransportState state;
  final Color fg;
  const _LinkBadge({required this.state, required this.fg});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      TransportState.connected => ('SIM ●', Colors.greenAccent),
      TransportState.connecting => ('connecting…', Colors.amberAccent),
      TransportState.error => ('error', Colors.redAccent),
      TransportState.disconnected => ('offline', fg),
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
