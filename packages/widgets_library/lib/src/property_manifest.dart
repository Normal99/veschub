/// Per-property capability-level metadata for the inspector.
///
/// The studio inspector consults this to decide which properties to reveal at
/// the user's chosen level. Basic mode shows only "safe" knobs (colour, label,
/// limits); Advanced adds layout/bindings; Expert exposes everything including
/// raw transform values and graph bindings.
library;

import 'package:dashboard_model/dashboard_model.dart';

/// Metadata for a single widget property.
class PropertyMeta {
  /// The property key (matches a [WidgetInstance.properties] key).
  final String key;

  /// Minimum level at which this property is editable in the inspector.
  final CapabilityLevel minLevel;

  /// Human-readable label.
  final String label;

  /// Whether this property is "safe" — editable even in Basic mode without
  /// breaking the dashboard (colours, labels, limits). Layout and bindings are
  /// not safe.
  final bool safe;

  const PropertyMeta({
    required this.key,
    required this.minLevel,
    required this.label,
    this.safe = false,
  });
}

const List<PropertyMeta> _gauge = [
  PropertyMeta(
    key: 'value',
    minLevel: CapabilityLevel.advanced,
    label: 'Value binding',
  ),
  PropertyMeta(
    key: 'min',
    minLevel: CapabilityLevel.basic,
    label: 'Minimum',
    safe: true,
  ),
  PropertyMeta(
    key: 'max',
    minLevel: CapabilityLevel.basic,
    label: 'Maximum',
    safe: true,
  ),
  PropertyMeta(
    key: 'label',
    minLevel: CapabilityLevel.basic,
    label: 'Label',
    safe: true,
  ),
  PropertyMeta(
    key: 'unit',
    minLevel: CapabilityLevel.basic,
    label: 'Unit',
    safe: true,
  ),
  PropertyMeta(
    key: 'color',
    minLevel: CapabilityLevel.basic,
    label: 'Colour',
    safe: true,
  ),
  PropertyMeta(
    key: 'accent',
    minLevel: CapabilityLevel.advanced,
    label: 'Accent colour',
  ),
];

const List<PropertyMeta> _bar = [
  PropertyMeta(
    key: 'value',
    minLevel: CapabilityLevel.advanced,
    label: 'Value binding',
  ),
  PropertyMeta(
    key: 'min',
    minLevel: CapabilityLevel.basic,
    label: 'Minimum',
    safe: true,
  ),
  PropertyMeta(
    key: 'max',
    minLevel: CapabilityLevel.basic,
    label: 'Maximum',
    safe: true,
  ),
  PropertyMeta(
    key: 'color',
    minLevel: CapabilityLevel.basic,
    label: 'Colour',
    safe: true,
  ),
  PropertyMeta(
    key: 'orientation',
    minLevel: CapabilityLevel.advanced,
    label: 'Orientation',
  ),
];

const List<PropertyMeta> _text = [
  PropertyMeta(
    key: 'value',
    minLevel: CapabilityLevel.advanced,
    label: 'Value binding',
  ),
  PropertyMeta(
    key: 'label',
    minLevel: CapabilityLevel.basic,
    label: 'Label',
    safe: true,
  ),
  PropertyMeta(
    key: 'unit',
    minLevel: CapabilityLevel.basic,
    label: 'Unit',
    safe: true,
  ),
  PropertyMeta(
    key: 'color',
    minLevel: CapabilityLevel.basic,
    label: 'Colour',
    safe: true,
  ),
];

const List<PropertyMeta> _status = [
  PropertyMeta(
    key: 'fault',
    minLevel: CapabilityLevel.advanced,
    label: 'Fault binding',
  ),
  PropertyMeta(
    key: 'label',
    minLevel: CapabilityLevel.basic,
    label: 'Label',
    safe: true,
  ),
  PropertyMeta(
    key: 'value',
    minLevel: CapabilityLevel.advanced,
    label: 'State text',
  ),
];

const List<PropertyMeta> _chart = [
  PropertyMeta(
    key: 'value',
    minLevel: CapabilityLevel.advanced,
    label: 'Value binding',
  ),
  PropertyMeta(
    key: 'min',
    minLevel: CapabilityLevel.basic,
    label: 'Y minimum',
    safe: true,
  ),
  PropertyMeta(
    key: 'max',
    minLevel: CapabilityLevel.basic,
    label: 'Y maximum',
    safe: true,
  ),
  PropertyMeta(
    key: 'window',
    minLevel: CapabilityLevel.advanced,
    label: 'Sample window',
  ),
  PropertyMeta(
    key: 'label',
    minLevel: CapabilityLevel.basic,
    label: 'Label',
    safe: true,
  ),
  PropertyMeta(
    key: 'unit',
    minLevel: CapabilityLevel.basic,
    label: 'Unit',
    safe: true,
  ),
  PropertyMeta(
    key: 'color',
    minLevel: CapabilityLevel.basic,
    label: 'Colour',
    safe: true,
  ),
];

const List<PropertyMeta> _image = [
  PropertyMeta(
    key: 'src',
    minLevel: CapabilityLevel.basic,
    label: 'Image source',
    safe: true,
  ),
  PropertyMeta(
    key: 'fit',
    minLevel: CapabilityLevel.advanced,
    label: 'Fit mode',
  ),
  PropertyMeta(
    key: 'tint',
    minLevel: CapabilityLevel.basic,
    label: 'Tint',
    safe: true,
  ),
  PropertyMeta(
    key: 'opacity',
    minLevel: CapabilityLevel.advanced,
    label: 'Opacity',
  ),
];

const List<PropertyMeta> _web = [
  PropertyMeta(
    key: 'url',
    minLevel: CapabilityLevel.basic,
    label: 'URL',
    safe: true,
  ),
  PropertyMeta(
    key: 'title',
    minLevel: CapabilityLevel.basic,
    label: 'Title',
    safe: true,
  ),
  PropertyMeta(
    key: 'js',
    minLevel: CapabilityLevel.advanced,
    label: 'JavaScript enabled',
  ),
];

/// The per-widget-kind property manifest.
const Map<String, List<PropertyMeta>> propertyManifest = {
  'gauge': _gauge,
  'bar': _bar,
  'text': _text,
  'status': _status,
  'chart': _chart,
  'image': _image,
  'web': _web,
};

/// Returns the properties of [widgetKind] visible at [level].
List<PropertyMeta> visibleProperties(
  String widgetKind,
  CapabilityLevel level,
) {
  final manifest = propertyManifest[widgetKind] ?? const <PropertyMeta>[];
  return manifest.where((m) => level.includes(m.minLevel)).toList();
}

/// Whether transforms (move/scale/rotate) are unlocked at [level].
///
/// Basic mode locks transforms (the user tweaks values only, not layout);
/// Advanced and Expert unlock free positioning.
bool transformsUnlockedAt(CapabilityLevel level) =>
    level.index >= CapabilityLevel.advanced.index;
