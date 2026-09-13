/// Veschub Dashboard — the runtime app.
///
/// In dev/debug this viewer is wired to a [VescSim] over an in-memory
/// [VirtualTransportPair], so the full decode → bind → render pipeline runs
/// with no hardware. Real BLE/USB transport adapters are planned but not yet
/// implemented — see FUTURE_FEATURES.md. First-run onboarding and persisted
/// settings gate the experience.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:dashboard_storage/dashboard_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:settings/settings.dart';
import 'package:templates/templates.dart';
import 'package:vesc_proto/vesc_proto.dart';
import 'package:vesc_sim/vesc_sim.dart';
import 'package:vesc_transport/vesc_transport.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';
import 'package:flutter/material.dart';

import 'onboarding/dashboard_onboarding.dart';
import 'settings/dashboard_settings_screen.dart';

const double kDefaultWidgetWidth = 300;
const double kDefaultWidgetHeight = 220;

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
  int _lastIngestTime = 0;
  bool _toolbarVisible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _store = TelemetryStore();
    _runtime = DashboardRuntime(document: sampleDocument(), store: _store);

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

    final settings = ref.read(settingsServiceProvider);
    if (settings.autoConnect) {
      _connect();
    }

    _runtime.start();
  }

  void _connect() {
    _pair.b.connect().then((_) => _sim.clientTransport.connect()).then((_) {
      if (!mounted) return;
      _sim.start();
    }).catchError((e) {
      if (mounted) {
        setState(() => _linkState = TransportState.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect failed: $e')),
        );
      }
    });
  }

  void _loadDocument(DashboardDocument doc) {
    _runtime.setDocument(doc);
    _resolved.clear();
    setState(() {});
  }

  void _showToolbar() {
    _hideTimer?.cancel();
    setState(() => _toolbarVisible = true);
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _toolbarVisible = false);
    });
  }

  Future<void> _exportDoc(DashboardDocument doc, BuildContext context) async {
    final json = const JsonEncoder.withIndent('  ').convert(doc.toJson());
    final dir = await getApplicationDocumentsDirectory();
    final safeName =
        doc.name.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
    final file = File('${dir.path}/$safeName.veschub.json');
    try {
      await file.writeAsString(json);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importDoc(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty || !context.mounted) return;

    final path = result.files.single.path;
    if (path == null) return;

    try {
      final raw = await File(path).readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final migrated = migrate(json);
      final doc = DashboardDocument.fromJson(migrated);
      _loadDocument(doc);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  void _onPayload(List<int> payload) {
    final settings = ref.read(settingsServiceProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final interval = (1000 / settings.dataRate).round();
    if (_lastIngestTime != 0 && now - _lastIngestTime < interval) return;
    _lastIngestTime = now;
    try {
      final v = TelemetryValues.fromPayload(payload);
      _store.ingest({
        TelemetryKey.erpm: v.erpm,
        TelemetryKey.duty: v.duty,
        TelemetryKey.vIn: v.vIn,
        TelemetryKey.tempMosfet: v.tempMosfet,
        TelemetryKey.tempMotor: v.tempMotor,
        TelemetryKey.currentMotor: v.currentMotor,
        TelemetryKey.currentInput: v.currentInput,
        TelemetryKey.focId: v.id,
        TelemetryKey.focIq: v.iq,
        TelemetryKey.ampHoursCharged: v.ampHoursCharged,
        TelemetryKey.ampHoursDischarged: v.ampHoursDischarged,
        TelemetryKey.wattHoursCharged: v.wattHoursCharged,
        TelemetryKey.wattHoursDischarged: v.wattHoursDischarged,
        TelemetryKey.tachometer: v.tachometer,
        TelemetryKey.tachometerAbs: v.tachometerAbs,
        TelemetryKey.fault: v.fault.code,
      });
    } catch (_) {
      // Ignore non-telemetry payloads.
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
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
    return Scaffold(
      body: Stack(
        children: [
          // Dashboard content
          Center(
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
          // Tap target to show toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 48,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _showToolbar,
            ),
          ),
          // Pop-out toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 250),
              offset: _toolbarVisible
                  ? Offset.zero
                  : const Offset(0, -1),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: _toolbarVisible ? 1.0 : 0.0,
                child: _DashboardToolbar(
                  docName: doc.name,
                  linkState: _linkState,
                  onConnect: _connect,
                  onShowTemplates: () => _showTemplatePicker(context),
                  onOpenSaved: () => _showOpenDialog(context),
                  onSettings: () =>
                      Navigator.of(context).pushNamed('/settings'),
                  onExport: () => _exportDoc(doc, context),
                  onImport: () => _importDoc(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _positioned(WidgetInstance w, {Key? key}) {
    final tx = w.transform[4];
    final ty = w.transform[5];
    final resolved = _resolved[w.id] ?? const <String, dynamic>{};
    final width = (resolved['width'] as num?)?.toDouble() ?? kDefaultWidgetWidth;
    final height = (resolved['height'] as num?)?.toDouble() ?? kDefaultWidgetHeight;
    return Positioned(
      key: key,
      left: tx,
      top: ty,
      child: SizedBox(
        width: width,
        height: height,
        child: RepaintBoundary(
          child: buildWidget(w, resolved),
        ),
      ),
    );
  }

  Future<void> _showTemplatePicker(BuildContext context) async {
    final templates = [
      ...builtInTemplates,
      ...advancedDashboardTemplates,
    ];

    final categories = <String, List<DashboardTemplate>>{};
    for (final t in templates) {
      categories.putIfAbsent(t.category, () => []).add(t);
    }
    final orderedCategories = categories.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Text('Select Template',
                          style: Theme.of(ctx).textTheme.titleMedium),
                      const Spacer(),
                      Text(
                          '${templates.length} templates',
                          style: Theme.of(ctx).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: orderedCategories.length,
                    itemBuilder: (ctx, i) {
                      final entry = orderedCategories[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: Theme.of(ctx)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: Theme.of(ctx).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ...entry.value.map(
                              (t) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    _iconFor(t.id),
                                    size: 32,
                                  ),
                                  title: Text(t.name),
                                  subtitle: Text(t.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () {
                                    _loadDocument(t.document);
                                    Navigator.of(ctx).pop();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'minimal' => Icons.speed,
        'performance' => Icons.bolt,
        'commuter' => Icons.directions_car,
        'offroad' => Icons.terrain,
        'tesla-model3' => Icons.electric_car,
        'porsche-taycan' => Icons.sports_motorsports,
        'bmw-classic' => Icons.precision_manufacturing,
        'audi-virtual-cockpit' => Icons.flight,
        'vesc-mobile' => Icons.sensors,
        'android-auto' => Icons.android,
        'carplay' => Icons.phone_iphone,
        'ford-digital' => Icons.local_shipping,
        'vw-digital' => Icons.airport_shuttle,
        _ => Icons.dashboard,
      };

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
                ? const Text(
                    'No saved dashboards yet. Author one in Studio.')
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

class _DashboardToolbar extends StatelessWidget {
  final String docName;
  final TransportState linkState;
  final VoidCallback onConnect;
  final VoidCallback onShowTemplates;
  final VoidCallback onOpenSaved;
  final VoidCallback onSettings;
  final VoidCallback onExport;
  final VoidCallback onImport;

  const _DashboardToolbar({
    required this.docName,
    required this.linkState,
    required this.onConnect,
    required this.onShowTemplates,
    required this.onOpenSaved,
    required this.onSettings,
    required this.onExport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white70 : Colors.black87;
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton.icon(
              onPressed: onShowTemplates,
              icon: const Icon(Icons.dashboard, size: 20),
              label: Text(
                'Veschub · $docName',
                style: TextStyle(color: fg, fontSize: 13),
              ),
            ),
          ),
          const Spacer(),
          _LinkBadge(state: linkState, fg: fg),
          const SizedBox(width: 4),
          if (linkState == TransportState.disconnected)
            IconButton(
              icon: Icon(Icons.bluetooth, color: fg, size: 22),
              onPressed: onConnect,
              tooltip: 'Connect',
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            icon: Icon(Icons.grid_view, color: fg, size: 22),
            onPressed: onShowTemplates,
            tooltip: 'Templates',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.folder, color: fg, size: 22),
            onPressed: onOpenSaved,
            tooltip: 'Open saved',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.tune, color: fg, size: 22),
            onPressed: onSettings,
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.save_alt, color: fg, size: 22),
            onPressed: onExport,
            tooltip: 'Export',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.file_open, color: fg, size: 22),
            onPressed: onImport,
            tooltip: 'Import',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
        ],
      ),
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
