import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';

void main(List<String> args) {
  String? dashboardPath;
  bool autoScreenshot = false;
  String? screenshotOutput;

  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--screenshot') {
      autoScreenshot = true;
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        screenshotOutput = args[++i];
      }
    } else if (!args[i].startsWith('--')) {
      dashboardPath = args[i];
    }
  }

  runApp(DashboardRendererApp(
    dashboardPath: dashboardPath,
    autoScreenshot: autoScreenshot,
    screenshotOutput: screenshotOutput,
  ));
}

class DashboardRendererApp extends StatelessWidget {
  final String? dashboardPath;
  final bool autoScreenshot;
  final String? screenshotOutput;

  const DashboardRendererApp({
    super.key,
    this.dashboardPath,
    this.autoScreenshot = false,
    this.screenshotOutput,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme:
            ThemeData.dark().textTheme.apply(fontFamily: kDashboardFontFamily),
      ),
      home: DashboardRenderer(
        dashboardPath: dashboardPath,
        autoScreenshot: autoScreenshot,
        screenshotOutput: screenshotOutput,
      ),
    );
  }
}

class DashboardRenderer extends StatefulWidget {
  final String? dashboardPath;
  final bool autoScreenshot;
  final String? screenshotOutput;

  const DashboardRenderer({
    super.key,
    this.dashboardPath,
    this.autoScreenshot = false,
    this.screenshotOutput,
  });

  @override
  State<DashboardRenderer> createState() => _DashboardRendererState();
}

class _DashboardRendererState extends State<DashboardRenderer> {
  DashboardDocument? _document;
  DashboardRuntime? _runtime;
  TelemetryStore? _store;
  String _status = 'Loading...';
  Map<String, ResolvedProperties> _resolved = {};

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      String path =
          widget.dashboardPath ?? 'examples/tesla_model3.veschub.json';
      print('Attempting to load dashboard from: $path');
      print('Current directory: ${Directory.current.path}');

      // Try relative path first, then absolute
      var file = File(path);
      if (!await file.exists()) {
        print('File not found at $path, trying ../../$path');
        // Try from project root
        file = File('../../$path');
      }

      if (!await file.exists()) {
        print('Dashboard not found: ${file.path}');
        setState(() {
          _status = 'Dashboard not found: $path';
        });
        return;
      }

      print('Loading dashboard from: ${file.path}');
      final jsonStr = await file.readAsString();
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final migrated = migrate(json);
      final document = DashboardDocument.fromJson(migrated);
      print(
          'Dashboard loaded: ${document.name} with ${document.widgets.length} widgets');

      // Create telemetry store with mock data
      final store = TelemetryStore();
      _populateMockTelemetry(store);

      // Create runtime
      final runtime = DashboardRuntime(
        document: document,
        store: store,
      );

      // Listen to dirty widget updates
      runtime.dirtyWidgets.listen((dirty) {
        if (mounted) {
          setState(() {
            _resolved = {..._resolved, ...dirty};
          });
        }
      });

      runtime.start();

      setState(() {
        _document = document;
        _runtime = runtime;
        _store = store;
        _status = 'Loaded: ${document.name}';
      });

      // Auto-screenshot after rendering completes
      if (widget.autoScreenshot) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          // Wait for widgets to render
          await Future.delayed(const Duration(milliseconds: 1000));
          if (mounted) {
            await _takeScreenshot();
          }
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error loading dashboard: $e';
      });
    }
  }

  void _populateMockTelemetry(TelemetryStore store) {
    // Populate with realistic VESC telemetry values
    store.update(TelemetryKey.erpm, 0.0);
    store.update(TelemetryKey.duty, 0.0);
    store.update(TelemetryKey.currentMotor, 0.0);
    store.update(TelemetryKey.currentInput, 0.0);
    store.update(TelemetryKey.vIn, 48.5);
    store.update(TelemetryKey.tempMotor, 45.0);
    store.update(TelemetryKey.tempMosfet, 38.0);
    store.update(TelemetryKey.ampHoursCharged, 0.0);
    store.update(TelemetryKey.ampHoursDischarged, 12.5);
    store.update(TelemetryKey.wattHoursCharged, 0.0);
    store.update(TelemetryKey.wattHoursDischarged, 600.0);
    store.update(TelemetryKey.tachometer, 403438.0);
    store.update(TelemetryKey.tachometerAbs, 403438.0);
    store.update(TelemetryKey.fault, 0);
    store.update(TelemetryKey.gpsSpeed, 0.0);

    // Additional keys for Tesla dashboard
    store.update('speed', 0.0);
    store.update('battery_pct', 85.0);
    store.update('range', 270.0);
    store.update('power', 0.0);
    store.update('odometer', 403.438);
    store.update('trip_distance', 45.2);
    store.update('trip_time', 78.0);
    store.update('avg_speed', 35.0);
    store.update('energy_used', 12.5);
  }

  Future<void> _takeScreenshot() async {
    print('Taking screenshot...');
    if (_document == null) {
      print('No document loaded, cannot take screenshot');
      return;
    }

    try {
      // Find the RepaintBoundary in the widget tree
      final repaintBoundary =
          context.findAncestorRenderObjectOfType<RenderRepaintBoundary>();
      if (repaintBoundary == null) {
        print('No RepaintBoundary found in widget tree');
        return;
      }

      final image = await repaintBoundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        print('Failed to capture screenshot: byteData is null');
        setState(() => _status = 'Failed to capture screenshot');
        return;
      }

      final pngBytes = byteData.buffer.asUint8List();
      final outputPath = widget.screenshotOutput ??
          '${_document!.name.replaceAll(' ', '_').toLowerCase()}_render.png';
      print('Saving screenshot to: $outputPath');
      final file = File(outputPath);
      await file.writeAsBytes(pngBytes);
      print('Screenshot saved successfully: ${file.path}');

      setState(() {
        _status = 'Screenshot saved: ${file.path}';
      });

      // Exit if auto-screenshot mode
      if (widget.autoScreenshot) {
        print('Auto-screenshot mode, exiting in 500ms...');
        await Future.delayed(const Duration(milliseconds: 500));
        exit(0);
      }
    } catch (e) {
      print('Screenshot error: $e');
      setState(() {
        _status = 'Screenshot error: $e';
      });
    }
  }

  @override
  void dispose() {
    _runtime?.dispose();
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_document == null) {
      return Scaffold(
        body: Center(
          child: Text(_status, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final canvasW = _document!.canvas.width;
    final canvasH = _document!.canvas.height;

    return Scaffold(
      backgroundColor: Color(_document!.background),
      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: canvasW,
            height: canvasH,
            child: RepaintBoundary(
              child: Container(
                color: Color(_document!.background),
                child: Stack(
                  children: [
                    // Render all widgets
                    for (final widget in _document!.widgets)
                      if (_resolved.containsKey(widget.id))
                        _buildWidget(widget, _resolved[widget.id]!),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidget(WidgetInstance widget, ResolvedProperties props) {
    final width = props['width']?.toDouble() ?? 300.0;
    final height = props['height']?.toDouble() ?? 220.0;
    final x = widget.transform[4];
    final y = widget.transform[5];

    return Positioned(
      left: x,
      top: y,
      child: SizedBox(
        width: width,
        height: height,
        child: buildWidget(widget, props),
      ),
    );
  }
}
