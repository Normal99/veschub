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
  final String key;
  final CapabilityLevel minLevel;
  final String label;
  final bool safe;

  const PropertyMeta({
    required this.key,
    required this.minLevel,
    required this.label,
    this.safe = false,
  });
}

const List<PropertyMeta> _gauge = [
  PropertyMeta(key: 'value', minLevel: CapabilityLevel.advanced, label: 'Value binding'),
  PropertyMeta(key: 'min', minLevel: CapabilityLevel.basic, label: 'Minimum', safe: true),
  PropertyMeta(key: 'max', minLevel: CapabilityLevel.basic, label: 'Maximum', safe: true),
  PropertyMeta(key: 'label', minLevel: CapabilityLevel.basic, label: 'Label', safe: true),
  PropertyMeta(key: 'unit', minLevel: CapabilityLevel.basic, label: 'Unit', safe: true),
  PropertyMeta(key: 'color', minLevel: CapabilityLevel.basic, label: 'Colour', safe: true),
  PropertyMeta(key: 'accent', minLevel: CapabilityLevel.advanced, label: 'Accent colour'),
  PropertyMeta(key: 'tickCount', minLevel: CapabilityLevel.advanced, label: 'Tick count'),
  PropertyMeta(key: 'sweepAngle', minLevel: CapabilityLevel.advanced, label: 'Sweep angle (°)'),
  PropertyMeta(key: 'startAngle', minLevel: CapabilityLevel.advanced, label: 'Start angle (°)'),
  PropertyMeta(key: 'arcWidth', minLevel: CapabilityLevel.advanced, label: 'Arc thickness'),
  PropertyMeta(key: 'needleStyle', minLevel: CapabilityLevel.advanced, label: 'Needle style'),
  PropertyMeta(key: 'backgroundColor', minLevel: CapabilityLevel.basic, label: 'Background', safe: true),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'fontSize', minLevel: CapabilityLevel.basic, label: 'Font size', safe: true),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'opacity', minLevel: CapabilityLevel.advanced, label: 'Opacity'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _bar = [
  PropertyMeta(key: 'value', minLevel: CapabilityLevel.advanced, label: 'Value binding'),
  PropertyMeta(key: 'min', minLevel: CapabilityLevel.basic, label: 'Minimum', safe: true),
  PropertyMeta(key: 'max', minLevel: CapabilityLevel.basic, label: 'Maximum', safe: true),
  PropertyMeta(key: 'color', minLevel: CapabilityLevel.basic, label: 'Colour', safe: true),
  PropertyMeta(key: 'orientation', minLevel: CapabilityLevel.advanced, label: 'Orientation'),
  PropertyMeta(key: 'backgroundColor', minLevel: CapabilityLevel.basic, label: 'Background', safe: true),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'fontSize', minLevel: CapabilityLevel.basic, label: 'Font size', safe: true),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'opacity', minLevel: CapabilityLevel.advanced, label: 'Opacity'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _text = [
  PropertyMeta(key: 'value', minLevel: CapabilityLevel.advanced, label: 'Value binding'),
  PropertyMeta(key: 'label', minLevel: CapabilityLevel.basic, label: 'Label', safe: true),
  PropertyMeta(key: 'unit', minLevel: CapabilityLevel.basic, label: 'Unit', safe: true),
  PropertyMeta(key: 'color', minLevel: CapabilityLevel.basic, label: 'Colour', safe: true),
  PropertyMeta(key: 'backgroundColor', minLevel: CapabilityLevel.basic, label: 'Background', safe: true),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'fontSize', minLevel: CapabilityLevel.basic, label: 'Font size', safe: true),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'opacity', minLevel: CapabilityLevel.advanced, label: 'Opacity'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _status = [
  PropertyMeta(key: 'fault', minLevel: CapabilityLevel.advanced, label: 'Fault binding'),
  PropertyMeta(key: 'label', minLevel: CapabilityLevel.basic, label: 'Label', safe: true),
  PropertyMeta(key: 'value', minLevel: CapabilityLevel.advanced, label: 'State text'),
  PropertyMeta(key: 'backgroundColor', minLevel: CapabilityLevel.basic, label: 'Background', safe: true),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'fontSize', minLevel: CapabilityLevel.basic, label: 'Font size', safe: true),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'opacity', minLevel: CapabilityLevel.advanced, label: 'Opacity'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _chart = [
  PropertyMeta(key: 'value', minLevel: CapabilityLevel.advanced, label: 'Value binding'),
  PropertyMeta(key: 'min', minLevel: CapabilityLevel.basic, label: 'Y minimum', safe: true),
  PropertyMeta(key: 'max', minLevel: CapabilityLevel.basic, label: 'Y maximum', safe: true),
  PropertyMeta(key: 'window', minLevel: CapabilityLevel.advanced, label: 'Sample window'),
  PropertyMeta(key: 'label', minLevel: CapabilityLevel.basic, label: 'Label', safe: true),
  PropertyMeta(key: 'unit', minLevel: CapabilityLevel.basic, label: 'Unit', safe: true),
  PropertyMeta(key: 'color', minLevel: CapabilityLevel.basic, label: 'Colour', safe: true),
  PropertyMeta(key: 'lineWidth', minLevel: CapabilityLevel.advanced, label: 'Line width'),
  PropertyMeta(key: 'showGrid', minLevel: CapabilityLevel.basic, label: 'Show grid', safe: true),
  PropertyMeta(key: 'gridColor', minLevel: CapabilityLevel.advanced, label: 'Grid colour'),
  PropertyMeta(key: 'smoothCurve', minLevel: CapabilityLevel.advanced, label: 'Smooth curve'),
  PropertyMeta(key: 'fillArea', minLevel: CapabilityLevel.advanced, label: 'Fill area'),
  PropertyMeta(key: 'fillColor', minLevel: CapabilityLevel.advanced, label: 'Fill colour'),
  PropertyMeta(key: 'backgroundColor', minLevel: CapabilityLevel.basic, label: 'Background', safe: true),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'fontSize', minLevel: CapabilityLevel.basic, label: 'Font size', safe: true),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'opacity', minLevel: CapabilityLevel.advanced, label: 'Opacity'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _image = [
  PropertyMeta(key: 'src', minLevel: CapabilityLevel.basic, label: 'Image source', safe: true),
  PropertyMeta(key: 'fit', minLevel: CapabilityLevel.advanced, label: 'Fit mode'),
  PropertyMeta(key: 'tint', minLevel: CapabilityLevel.basic, label: 'Tint', safe: true),
  PropertyMeta(key: 'opacity', minLevel: CapabilityLevel.advanced, label: 'Opacity'),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _web = [
  PropertyMeta(key: 'url', minLevel: CapabilityLevel.basic, label: 'URL', safe: true),
  PropertyMeta(key: 'title', minLevel: CapabilityLevel.basic, label: 'Title', safe: true),
  PropertyMeta(key: 'js', minLevel: CapabilityLevel.advanced, label: 'JavaScript enabled'),
  PropertyMeta(key: 'borderRadius', minLevel: CapabilityLevel.advanced, label: 'Corner radius'),
  PropertyMeta(key: 'borderWidth', minLevel: CapabilityLevel.advanced, label: 'Border width'),
  PropertyMeta(key: 'borderColor', minLevel: CapabilityLevel.advanced, label: 'Border colour'),
  PropertyMeta(key: 'shadowColor', minLevel: CapabilityLevel.advanced, label: 'Shadow colour'),
  PropertyMeta(key: 'shadowBlur', minLevel: CapabilityLevel.advanced, label: 'Shadow blur'),
  PropertyMeta(key: 'shadowOffsetY', minLevel: CapabilityLevel.advanced, label: 'Shadow offset Y'),
  PropertyMeta(key: 'padding', minLevel: CapabilityLevel.basic, label: 'Padding', safe: true),
  PropertyMeta(key: 'width', minLevel: CapabilityLevel.basic, label: 'Width', safe: true),
  PropertyMeta(key: 'height', minLevel: CapabilityLevel.basic, label: 'Height', safe: true),
];

const List<PropertyMeta> _paint = [
  PropertyMeta(key: 'program', minLevel: CapabilityLevel.expert, label: 'Paint program (DSL)'),
];

const Map<String, List<PropertyMeta>> propertyManifest = {
  'gauge': _gauge,
  'bar': _bar,
  'text': _text,
  'status': _status,
  'chart': _chart,
  'image': _image,
  'web': _web,
  'paint': _paint,
};

List<PropertyMeta> visibleProperties(String widgetKind, CapabilityLevel level) {
  final manifest = propertyManifest[widgetKind] ?? const <PropertyMeta>[];
  return manifest.where((m) => level.includes(m.minLevel)).toList();
}

List<PropertyMeta> allProperties(String widgetKind) {
  return (propertyManifest[widgetKind] ?? const <PropertyMeta>[]).toList();
}

bool transformsUnlockedAt(CapabilityLevel level) =>
    level.index >= CapabilityLevel.advanced.index;
