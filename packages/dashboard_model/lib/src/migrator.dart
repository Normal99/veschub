/// Schema migrations for [DashboardDocument].
///
/// Documents carry a [version]; older documents are upgraded in place by
/// [migrate] before being rendered or edited. Add a step per schema bump.
library;

import 'document.dart';

/// Migrates [json] (a raw decoded document) to [kCurrentDocumentVersion].
///
/// Returns a new `Map<String, dynamic>` at the current version. Throws if the
/// version is newer than what this build understands.
Map<String, dynamic> migrate(Map<String, dynamic> json) {
  final version = (json['version'] as int?) ?? 1;
  if (version > kCurrentDocumentVersion) {
    throw StateError(
      'Document version $version is newer than supported $kCurrentDocumentVersion',
    );
  }
  final out = Map<String, dynamic>.from(json);

  // Example migration scaffold (no-op until version 2 exists):
  // if (version < 2) { out = _migrateV1ToV2(out); }

  out['version'] = kCurrentDocumentVersion;
  return out;
}
