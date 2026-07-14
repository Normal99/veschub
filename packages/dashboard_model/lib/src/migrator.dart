/// Schema migrations for [DashboardDocument].
///
/// Documents carry a [version]; older documents are upgraded in place by
/// [migrate] before being rendered or edited. Each schema bump registers a
/// step function in [_steps] that transforms the raw JSON from version `n` to
/// `n + 1`. The registry pattern keeps migrations auditable and testable, and
/// makes the format OTA-friendly: an older build rejects (rather than
/// silently corrupts) a newer document, while a newer build upgrades any older
/// one.
library;

import 'document.dart';

/// A single migration step: transforms a document's raw JSON from [from] to
/// `from + 1`. Steps must be pure and idempotent-safe.
typedef MigrationStep = Map<String, dynamic> Function(
  Map<String, dynamic> json,
);

/// Ordered registry of migration steps, keyed by the *source* version.
///
/// `_steps[1]` upgrades a v1 document to v2, `_steps[2]` v2→v3, and so on.
/// Add one entry per schema bump.
const Map<int, MigrationStep> _steps = {
  // v1 → v2: introduce the optional `description` field (default empty string)
  // so v1 documents normalize to the current shape before decoding.
  1: _migrateV1ToV2,
};

Map<String, dynamic> _migrateV1ToV2(Map<String, dynamic> json) {
  final out = Map<String, dynamic>.from(json);
  out.putIfAbsent('description', () => '');
  return out;
}

/// Migrates [json] (a raw decoded document) to [kCurrentDocumentVersion].
///
/// Returns a new `Map<String, dynamic>` at the current version. Throws a
/// [StateError] if the version is newer than what this build understands.
Map<String, dynamic> migrate(Map<String, dynamic> json) {
  final version = (json['version'] as int?) ?? 1;
  if (version > kCurrentDocumentVersion) {
    throw StateError(
      'Document version $version is newer than supported '
      '$kCurrentDocumentVersion',
    );
  }

  var out = Map<String, dynamic>.from(json);
  var current = version;
  while (current < kCurrentDocumentVersion) {
    final step = _steps[current];
    if (step == null) {
      throw StateError(
        'No migration step registered from version $current',
      );
    }
    out = step(out);
    current++;
  }
  out['version'] = kCurrentDocumentVersion;
  return out;
}
