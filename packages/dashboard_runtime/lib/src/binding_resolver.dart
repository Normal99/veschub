/// Resolves a [Binding] to a concrete value using a [TelemetryStore].
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';

/// Result of resolving a binding.
class ResolvedValue {
  final dynamic value;
  final bool isResolved;

  const ResolvedValue(this.value, {this.isResolved = true});
  const ResolvedValue.unresolved()
      : value = null,
        isResolved = false;
}

/// Resolves [binding] against [store]. Literal bindings return their baked
/// value; telemetry bindings read the store (or unresolved if unset); graph
/// bindings are unresolved at Phase 2 (wired in Phase 6).
ResolvedValue resolveBinding(Binding binding, TelemetryStore store) {
  return binding.map(
    literal: (b) => ResolvedValue(b.value),
    telemetry: (b) {
      if (!store.contains(b.key)) return const ResolvedValue.unresolved();
      return ResolvedValue(store.value(b.key));
    },
    graph: (_) => const ResolvedValue.unresolved(),
  );
}
