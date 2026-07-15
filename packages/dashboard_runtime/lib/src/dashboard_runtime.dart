/// The dashboard runtime: subscribes to telemetry, evaluates a document's
/// bindings, and emits the set of widget ids whose values changed (dirty set).
///
/// The Flutter layer wraps each widget in a `RepaintBoundary` and only the
/// dirty widgets repaint — critical for Pi performance.
library;

import 'dart:async';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

import 'binding_resolver.dart';

/// A snapshot of a widget's resolved properties.
typedef ResolvedProperties = Map<String, dynamic>;

/// Emits, for each dirty widget id, its newly-resolved properties.
class DashboardRuntime {
  DashboardDocument _document;
  final TelemetryStore _store;
  GraphRegistry _graphs = GraphRegistry.empty;
  final Map<String, ResolvedProperties> _lastValues = {};
  final StreamController<Map<String, ResolvedProperties>> _dirtyController =
      StreamController<Map<String, ResolvedProperties>>.broadcast(sync: true);

  final Set<String> _watchedKeys = {};

  DashboardRuntime({
    required DashboardDocument document,
    required TelemetryStore store,
  })  : _document = document,
        _store = store;

  /// The current document.
  DashboardDocument get document => _document;

  /// Stream of dirty maps: `{widgetId: {propName: resolvedValue, ...}}`.
  Stream<Map<String, ResolvedProperties>> get dirtyWidgets =>
      _dirtyController.stream;

  /// Replaces the active document and re-evaluates everything.
  void setDocument(DashboardDocument doc) {
    _document = doc;
    _graphs = GraphRegistry.fromDocument(doc);
    _lastValues.clear();
    _syncWatchedKeys();
    // Defer so listeners attached synchronously after setDocument receive it.
    scheduleMicrotask(_recomputeAll);
  }

  /// Begins evaluating bindings whenever watched telemetry keys change.
  void start() {
    _graphs = GraphRegistry.fromDocument(_document);
    _syncWatchedKeys();
    // Defer the initial emission so listeners attached synchronously after
    // start() receive the first dirty set (broadcast streams drop events with
    // no listener).
    scheduleMicrotask(_recomputeAll);
  }

  /// Stops listening. Call from dispose.
  void dispose() {
    for (final sub in _subs.values) {
      sub.cancel();
    }
    _subs.clear();
    _dirtyController.close();
  }

  /// Returns the resolved properties for [widgetId] at the current store state.
  ResolvedProperties resolvedFor(String widgetId) {
    final w = _document.widgets.firstWhere(
      (w) => w.id == widgetId,
      orElse: () => throw ArgumentError('No widget $widgetId'),
    );
    return _resolveWidget(w);
  }

  void _syncWatchedKeys() {
    final needed = <String>{};
    for (final w in _document.widgets) {
      for (final b in w.properties.values) {
        b.mapOrNull(
          telemetry: (t) => needed.add(t.key),
          literal: (_) {},
          graph: (_) {},
        );
      }
    }

    for (final k in _watchedKeys.toList()) {
      if (!needed.contains(k)) _unwatchKey(k);
    }
    for (final k in needed) {
      if (!_watchedKeys.contains(k)) _watchKey(k);
    }
  }

  void _watchKey(String key) {
    _watchedKeys.add(key);
    final sub =
        _store.watch(key, replayLast: false).listen((_) => _recomputeAll());
    _subs[key] = sub;
  }

  void _unwatchKey(String key) {
    _watchedKeys.remove(key);
    final sub = _subs.remove(key);
    sub?.cancel();
  }

  final Map<String, StreamSubscription<dynamic>> _subs = {};

  void _recomputeAll() {
    final dirty = <String, ResolvedProperties>{};
    for (final w in _document.widgets) {
      final resolved = _resolveWidget(w);
      final prev = _lastValues[w.id];
      if (prev == null || !_mapsEqual(prev, resolved)) {
        _lastValues[w.id] = resolved;
        dirty[w.id] = resolved;
      }
    }
    if (dirty.isNotEmpty) _dirtyController.add(dirty);
  }

  ResolvedProperties _resolveWidget(WidgetInstance w) {
    final out = <String, dynamic>{};
    for (final entry in w.properties.entries) {
      final r = resolveBinding(entry.value, _store, graphs: _graphs);
      if (r.isResolved) out[entry.key] = r.value;
    }
    return out;
  }

  bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}
