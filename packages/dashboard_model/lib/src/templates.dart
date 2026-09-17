/// Starter dashboard templates for Template mode.
///
/// A [DashboardTemplate] is a pre-built [DashboardDocument] plus editable
/// "knobs" — a restricted set of properties tweakable right in the template
/// gallery (colours, units, limits). Full editing is done in Canvas/Flow
/// mode instead.
library;

import 'package:dashboard_model/dashboard_model.dart';

/// A single editable knob exposed in Template mode.
class TemplateKnob {
  /// The widget id this knob targets (matches a [WidgetInstance.id]).
  final String widgetId;

  /// The property name on that widget (matches a [WidgetInstance.properties] key).
  final String property;

  /// Human-readable label shown in the tweak panel.
  final String label;

  /// What kind of editor to render for this knob.
  final KnobKind kind;

  const TemplateKnob({
    required this.widgetId,
    required this.property,
    required this.label,
    required this.kind,
  });
}

/// The editor flavour for a [TemplateKnob].
enum KnobKind {
  /// A numeric value (min/max/threshold).
  number,

  /// An ARGB colour int.
  color,

  /// A free-text label or unit.
  text,
}

/// A starter dashboard: a document scaffold + the knobs a Basic user may edit.
class DashboardTemplate {
  final String id;
  final String name;
  final String description;
  final String category;

  /// The base document. Knob edits are applied on top of this.
  final DashboardDocument document;

  /// The restricted set of properties exposed for tweaking.
  final List<TemplateKnob> knobs;

  const DashboardTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.category = '',
    required this.document,
    required this.knobs,
  });

  /// Applies [edits] (knob property → new value) onto a copy of [document],
  /// returning a new [DashboardDocument] ready to render or save.
  DashboardDocument applyEdits(Map<String, Object> edits) {
    final widgets = document.widgets.map((w) {
      final props = Map<String, Binding>.from(w.properties);
      for (final entry in edits.entries) {
        if (entry.key.startsWith('${w.id}.')) {
          final prop = entry.key.substring(w.id.length + 1);
          props[prop] = Binding.literal(value: entry.value);
        }
      }
      return w.copyWith(properties: props);
    }).toList();
    return document.copyWith(widgets: widgets);
  }
}
