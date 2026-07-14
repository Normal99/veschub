/// Veschub Studio — Phase 3 placeholder.
///
/// The editor (Canvas mode, drag-drop palette, properties inspector, save/load
/// to drift) is built in Phase 3 on top of `editor_canvas`. This entrypoint is
/// a placeholder so the app boots and the workspace stays green.
library;

import 'package:flutter/material.dart';

void main() {
  runApp(const StudioApp());
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veschub Studio',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const StudioPlaceholder(),
    );
  }
}

class StudioPlaceholder extends StatelessWidget {
  const StudioPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Veschub Studio')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize, size: 64),
              SizedBox(height: 16),
              Text('Studio editor — Phase 3',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text(
                'The scene-graph editor canvas, widget palette, properties '
                'inspector and drift-backed save/load land in Phase 3.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
