/// A typed telemetry value store with per-key streams.
///
/// The store is a `Map<String, dynamic>` keyed by canonical field names (see
/// [TelemetryKey]). Each key exposes a broadcast [Stream] of values via
/// [watch]; [value] returns the latest. The store is the single source of truth
/// the dashboard runtime binds against.
library;

import 'dart:async';

import 'telemetry_key.dart';

/// Typed, in-memory telemetry store.
///
/// Values may be any JSON-encodable type (num, bool, String). Numeric keys are
/// the norm; [watch] emits every update to a key, including the initial value
/// if present at subscription time when [replayLast] is true.
class TelemetryStore {
  final Map<String, dynamic> _values = {};
  final Map<String, StreamController<dynamic>> _controllers = {};

  /// The latest value for [key], or `null` if never set.
  dynamic value(String key) => _values[key];

  /// Whether [key] has ever been written.
  bool contains(String key) => _values.containsKey(key);

  /// All keys currently present in the store.
  Iterable<String> get keys => _values.keys;

  /// Updates [key] to [value] and notifies subscribers.
  void update(String key, dynamic value) {
    if (_disposed) return;
    _values[key] = value;
    _controllerFor(key).add(value);
  }

  /// Removes [key] and closes its stream (if any).
  void remove(String key) {
    if (_disposed) return;
    _values.remove(key);
    final c = _controllers.remove(key);
    c?.close();
  }

  /// Returns a broadcast stream of values for [key]. If [replayLast] is true
  /// (default) and a value already exists, it is emitted once on subscribe.
  Stream<dynamic> watch(String key, {bool replayLast = true}) {
    if (_disposed) return const Stream.empty();
    final controller = _controllerFor(key);
    late StreamSubscription<dynamic> sub;
    late StreamController<dynamic> out;
    out = StreamController<dynamic>.broadcast(
      sync: true,
      onCancel: () => sub.cancel(),
      onListen: () {
        // Replay the current value synchronously when the first listener
        // attaches, so it precedes any subsequent updates.
        if (replayLast && _values.containsKey(key)) {
          out.add(_values[key]);
        }
      },
    );
    sub = controller.stream
        .listen(out.add, onError: out.addError, onDone: out.close);
    return out.stream;
  }

  StreamController<dynamic> _controllerFor(String key) => _controllers
      .putIfAbsent(key, () => StreamController<dynamic>.broadcast(sync: true));

  /// Closes all per-key streams. The store cannot be reused after this.
  void dispose() {
    _disposed = true;
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
    _values.clear();
  }

  bool _disposed = false;
}
