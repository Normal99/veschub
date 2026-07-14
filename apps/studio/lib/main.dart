/// Veschub Studio — the dashboard editor app.
///
/// Phase 3: Canvas mode is live (drag-drop, move/snap, undo/redo, save/load
/// to drift). Template mode (Phase 5) and Flow mode (Phase 6) are stubbed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'editor/studio_editor.dart';

void main() {
  runApp(const ProviderScope(child: StudioApp()));
}

class StudioApp extends StatelessWidget {
  const StudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veschub Studio',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      home: const StudioEditor(),
    );
  }
}
