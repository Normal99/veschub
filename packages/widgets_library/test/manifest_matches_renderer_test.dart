// Regression guard for the "manifest/renderer drift" bug class: a widget
// kind's renderer reads a property that isn't declared in its
// PropertyMeta list, so a user can never find or adjust it in the
// inspector (this exact class of bug was found live during the AI
// dashboards push — text/chart manifests were missing backgroundColor/
// borderRadius/fontSize that their renderers actually read).
//
// This can't be checked at compile time (properties flow through a
// dynamic ResolvedProperties map), so instead it statically scans each
// widget's own source file for the property-access patterns used across
// this codebase and diffs that against allProperties(kind).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

/// Common properties every widget gets "for free" by calling one of the
/// shared cosmetic_helpers — these don't appear as a literal
/// `properties['x']` access in the widget's own file, so a plain regex
/// scan would otherwise flag them as undeclared-but-read.
const _helperImpliedKeys = {
  'resolveBoxDecoration(': [
    'backgroundColor',
    'borderRadius',
    'borderWidth',
    'borderColor',
    'shadowColor',
    'shadowBlur',
    'shadowOffsetY',
  ],
  'resolvePadding(': ['padding'],
  'applyOpacity(': ['opacity'],
  'applyTextStyle(': ['fontFamily', 'fontWeight', 'letterSpacing'],
};

/// Kinds excluded from the scan, with the reason it's a false positive
/// rather than a real gap.
const _skipKinds = <String>{
  // image calls resolveBoxDecoration(properties) but immediately discards
  // its background via .copyWith(color: Colors.transparent) — the image
  // itself is always rendered on a transparent container by design, so a
  // backgroundColor manifest entry would be a control that visibly does
  // nothing.
  'image',
};

final _directKeyPattern = RegExp(r"properties\['([a-zA-Z_][a-zA-Z0-9_]*)'\]");
final _helperAccessorPattern = RegExp(
  r"prop(?:Double|Int|Bool|Color|DoubleOpt)\(\s*(?:widget\.)?properties,\s*'([a-zA-Z_][a-zA-Z0-9_]*)'",
);

Set<String> _readKeysFor(String kind) {
  final file = File('lib/widgets/${kind}_widget.dart');
  final src = file.readAsStringSync();
  final keys = <String>{
    ..._directKeyPattern.allMatches(src).map((m) => m.group(1)!),
    ..._helperAccessorPattern.allMatches(src).map((m) => m.group(1)!),
  };
  for (final entry in _helperImpliedKeys.entries) {
    if (src.contains(entry.key)) keys.addAll(entry.value);
  }
  return keys;
}

void main() {
  test('every property a widget renderer reads is declared in its manifest',
      () {
    final failures = <String>[];
    for (final kind in builtInWidgets.keys) {
      if (_skipKinds.contains(kind)) continue;
      final declared = allProperties(kind).map((m) => m.key).toSet();
      final read = _readKeysFor(kind);
      final undeclared = read.difference(declared);
      if (undeclared.isNotEmpty) {
        failures.add('$kind: reads $undeclared but manifest declares none '
            'of them — add to property_manifest.dart or the property is '
            'invisible in the inspector.');
      }
    }
    expect(failures, isEmpty, reason: failures.join('\n'));
  });
}
