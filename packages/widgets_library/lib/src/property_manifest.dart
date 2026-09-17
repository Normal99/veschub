/// Per-property metadata for the inspector: label, category, numeric
/// bounds, and (for fixed-vocabulary strings) the picker options to show.
/// Every property is always visible — there is no capability-level gating.
library;

/// Categories for grouping widget properties in the property inspector.
enum PropertyCategory {
  // Declaration order matters beyond display: the inspector auto-expands
  // only the first non-empty category for a freshly-selected widget (see
  // _PropertiesInspector._buildProperties in studio_inspector.dart).
  // Data Bindings goes first — "what value does this actually show" is the
  // one thing every widget needs set and previously lost out to Visuals
  // (label/unit/etc, present on almost every kind) for that auto-expand
  // slot, making the binding editor easy to miss entirely on a fresh drop.
  dataBindings('Data Bindings'),
  visuals('Visuals'),
  layoutAndSpacing('Layout & Spacing'),
  fontsAndColors('Fonts & Colors');

  final String label;
  const PropertyCategory(this.label);

  String get displayName => label;
}

/// One choice in a fixed-vocabulary property's picker: [value] is the raw
/// string a widget's renderer actually compares against (e.g. `'kmh'`),
/// [label] is what the inspector shows for it (e.g. `'km/h'`).
class EnumOption {
  final String label;
  final String value;
  const EnumOption({required this.label, required this.value});
}

/// Metadata for a single widget property.
class PropertyMeta {
  final String key;
  final String label;
  final bool safe;
  final PropertyCategory category;
  final double? min;
  final double? max;
  final double? step;

  /// For a `String` property with a fixed set of valid values (a "style",
  /// unit, or mode toggle rather than free text) — when set, the inspector
  /// shows a searchable picker listing exactly these instead of a raw text
  /// field the user has no way to know the valid values for.
  final List<EnumOption>? options;

  const PropertyMeta({
    required this.key,
    required this.label,
    this.safe = false,
    this.category = PropertyCategory.visuals,
    this.min,
    this.max,
    this.step,
    this.options,
  });
}

/// Shared option lists for the speed/temperature unit properties that
/// appear on more than one widget kind (digitalspeed, minigauge) — see
/// `speedUnitFromString`/`temperatureUnitFromString` in `src/format.dart`
/// for the vocabulary these values are parsed against.
const List<EnumOption> _speedUnitOptions = [
  EnumOption(label: 'km/h', value: 'kmh'),
  EnumOption(label: 'mph', value: 'mph'),
  EnumOption(label: 'm/s', value: 'ms'),
];

/// `displayUnit` additionally accepts empty (unset) meaning "off — show the
/// raw value with no conversion", the default until a user opts in.
const List<EnumOption> _speedDisplayUnitOptions = [
  EnumOption(label: 'Off (no conversion)', value: ''),
  ..._speedUnitOptions,
];

const List<EnumOption> _temperatureUnitOptions = [
  EnumOption(label: 'Celsius (°C)', value: 'celsius'),
  EnumOption(label: 'Fahrenheit (°F)', value: 'fahrenheit'),
  EnumOption(label: 'Kelvin (K)', value: 'kelvin'),
];

const List<EnumOption> _temperatureDisplayUnitOptions = [
  EnumOption(label: 'Off (no conversion)', value: ''),
  ..._temperatureUnitOptions,
];

/// OOP wrapper for widget property manifest definitions.
class WidgetManifest {
  final String kind;
  const WidgetManifest(this.kind);

  static WidgetManifest forKind(String kind) => WidgetManifest(kind);

  List<PropertyMeta> get properties => allProperties(kind);

  Map<PropertyCategory, List<PropertyMeta>> get categorizedProperties =>
      _groupPropertiesByCategory(kind);

  List<PropertyMeta> getPropertiesByCategory(PropertyCategory category) =>
      (_groupPropertiesByCategory(kind)[category] ?? const <PropertyMeta>[]);
}

const List<PropertyMeta> _gauge = [
  PropertyMeta(
      key: 'value',
      label: 'Value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'min',
      label: 'Minimum',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'max',
      label: 'Maximum',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'unit',
      label: 'Unit',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'tickCount',
      label: 'Ticks',
      category: PropertyCategory.visuals,
      min: 2,
      max: 50,
      step: 1),
  PropertyMeta(
      key: 'sweepAngle',
      label: 'Sweep',
      category: PropertyCategory.visuals,
      min: 10,
      max: 360,
      step: 5),
  PropertyMeta(
      key: 'startAngle',
      label: 'Start angle',
      category: PropertyCategory.visuals,
      min: 0,
      max: 360,
      step: 5),
  PropertyMeta(
      key: 'arcWidth',
      label: 'Arc width',
      category: PropertyCategory.visuals,
      min: 1,
      max: 50,
      step: 1),
  PropertyMeta(
      key: 'needleStyle',
      label: 'Needle',
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Needle', value: 'needle'),
        EnumOption(label: 'None', value: 'none'),
      ]),
  PropertyMeta(
      key: 'showCenterText',
      label: 'Center text',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'centerValue',
      label: 'Center value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'centerUnit',
      label: 'Center unit',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'subLabel',
      label: 'Sub-label',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showTickLabels',
      label: 'Tick labels',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'innerValue',
      label: 'Inner value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'innerMin',
      label: 'Inner min',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'innerMax',
      label: 'Inner max',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'innerColor',
      label: 'Inner colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'innerArcWidth',
      label: 'Inner arc',
      category: PropertyCategory.visuals,
      min: 1,
      max: 30,
      step: 1),
  PropertyMeta(
      key: 'redlineStart',
      label: 'Redline',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'redlineColor',
      label: 'Redline colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _bar = [
  PropertyMeta(
      key: 'value',
      label: 'Value binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'min',
      label: 'Minimum',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'max',
      label: 'Maximum',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'orientation',
      label: 'Orientation',
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Horizontal', value: 'horizontal'),
        EnumOption(label: 'Vertical', value: 'vertical'),
      ]),
  PropertyMeta(
      key: 'showValue',
      label: 'Show value',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'gradient',
      label: 'Gradient fill',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'gradientColor',
      label: 'Gradient colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'barRadius',
      label: 'Bar fill radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _text = [
  PropertyMeta(
      key: 'value',
      label: 'Value binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'unit',
      label: 'Unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _status = [
  PropertyMeta(
      key: 'fault',
      label: 'Fault binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'value',
      label: 'State text',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _chart = [
  PropertyMeta(
      key: 'value',
      label: 'Value binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'min',
      label: 'Y minimum',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'max',
      label: 'Y maximum',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'window',
      label: 'Sample window',
      category: PropertyCategory.visuals,
      min: 10,
      max: 600,
      step: 10),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'unit',
      label: 'Unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'lineWidth',
      label: 'Line width',
      category: PropertyCategory.visuals,
      min: 0.5,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'showGrid',
      label: 'Show grid',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'gridColor',
      label: 'Grid colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'smoothCurve',
      label: 'Smooth curve',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'fillArea',
      label: 'Fill area',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'fillColor',
      label: 'Fill colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _image = [
  PropertyMeta(
      key: 'src',
      label: 'Image source',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'fit',
      label: 'Fit mode',
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Contain', value: 'contain'),
        EnumOption(label: 'Cover', value: 'cover'),
        EnumOption(label: 'Fill', value: 'fill'),
        EnumOption(label: 'Fit width', value: 'fitWidth'),
        EnumOption(label: 'Fit height', value: 'fitHeight'),
        EnumOption(label: 'None', value: 'none'),
      ]),
  PropertyMeta(
      key: 'tint',
      label: 'Tint',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
];

const List<PropertyMeta> _web = [
  PropertyMeta(
      key: 'url',
      label: 'URL',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'title',
      label: 'Title',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'js',
      label: 'JavaScript enabled',
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _paint = [
  PropertyMeta(
      key: 'program',
      label: 'Paint program (DSL)',
      category: PropertyCategory.visuals),
];

const List<PropertyMeta> _digitalspeed = [
  PropertyMeta(
      key: 'value',
      label: 'Value binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit',
      label: 'Unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'sourceUnit',
      label: 'Source unit',
      category: PropertyCategory.dataBindings,
      options: _speedUnitOptions),
  PropertyMeta(
      key: 'displayUnit',
      label: 'Display unit',
      safe: true,
      category: PropertyCategory.dataBindings,
      options: _speedDisplayUnitOptions),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'showUnit',
      label: 'Show unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'subLabel',
      label: 'Sub-label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'subValue',
      label: 'Sub-value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _music = [
  PropertyMeta(
      key: 'title',
      label: 'Track title',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'artist',
      label: 'Artist',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'album',
      label: 'Album',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'progress',
      label: 'Progress (s)',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'duration',
      label: 'Duration (s)',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'showControls',
      label: 'Show controls',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'albumColor',
      label: 'Album art colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _tripstats = [
  PropertyMeta(
      key: 'label1',
      label: 'Stat 1 label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'value1',
      label: 'Stat 1 value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit1',
      label: 'Stat 1 unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'label2',
      label: 'Stat 2 label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'value2',
      label: 'Stat 2 value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit2',
      label: 'Stat 2 unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'label3',
      label: 'Stat 3 label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'value3',
      label: 'Stat 3 value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit3',
      label: 'Stat 3 unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'label4',
      label: 'Stat 4 label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'value4',
      label: 'Stat 4 value',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit4',
      label: 'Stat 4 unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'layoutStyle',
      label: 'Layout style',
      safe: true,
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Standard list', value: 'standard'),
        EnumOption(label: '3x3 grid', value: '3x3'),
        EnumOption(label: 'Porsche pod', value: 'porsche'),
      ]),
  PropertyMeta(
      key: 'section1Header',
      label: 'Section 1 Header',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section1Val1',
      label: 'Section 1 Value 1',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit1_1',
      label: 'Section 1 Unit 1',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section1Val2',
      label: 'Section 1 Value 2',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit1_2',
      label: 'Section 1 Unit 2',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section1Val3',
      label: 'Section 1 Value 3',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit1_3',
      label: 'Section 1 Unit 3',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section2Header',
      label: 'Section 2 Header',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section2Val1',
      label: 'Section 2 Value 1',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit2_1',
      label: 'Section 2 Unit 1',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section2Val2',
      label: 'Section 2 Value 2',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit2_2',
      label: 'Section 2 Unit 2',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section2Val3',
      label: 'Section 2 Value 3',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit2_3',
      label: 'Section 2 Unit 3',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section3Header',
      label: 'Section 3 Header',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section3Val1',
      label: 'Section 3 Value 1',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit3_1',
      label: 'Section 3 Unit 1',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section3Val2',
      label: 'Section 3 Value 2',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit3_2',
      label: 'Section 3 Unit 2',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'section3Val3',
      label: 'Section 3 Value 3',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit3_3',
      label: 'Section 3 Unit 3',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'columns',
      label: 'Columns',
      safe: true,
      category: PropertyCategory.visuals,
      min: 1,
      max: 6,
      step: 1),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _power = [
  PropertyMeta(
      key: 'power',
      label: 'Power binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'maxPower',
      label: 'Max power',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'regen',
      label: 'Regen binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'maxRegen',
      label: 'Max regen',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'color',
      label: 'Power colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'regenColor',
      label: 'Regen colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'showBars',
      label: 'Show bars',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _warnings = [
  PropertyMeta(
      key: 'activeWarnings',
      label: 'Active warnings',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'color',
      label: 'Error colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'warningColor',
      label: 'Warning colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'infoColor',
      label: 'Info colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'iconSize',
      label: 'Icon size',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showLabels',
      label: 'Show labels',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _minigauge = [
  PropertyMeta(
      key: 'value',
      label: 'Value binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'min',
      label: 'Minimum',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'max',
      label: 'Maximum',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'unit',
      label: 'Unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'sourceUnit',
      label: 'Source temperature unit',
      category: PropertyCategory.dataBindings,
      options: _temperatureUnitOptions),
  PropertyMeta(
      key: 'displayUnit',
      label: 'Display temperature unit',
      safe: true,
      category: PropertyCategory.dataBindings,
      options: _temperatureDisplayUnitOptions),
  PropertyMeta(
      key: 'icon',
      label: 'Icon',
      safe: true,
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'None', value: ''),
        EnumOption(label: 'Battery', value: 'battery'),
        EnumOption(label: 'Temperature', value: 'temp'),
        EnumOption(label: 'Fuel', value: 'fuel'),
        EnumOption(label: 'Speed', value: 'speed'),
        EnumOption(label: 'Power', value: 'power'),
      ]),
  PropertyMeta(
      key: 'style',
      label: 'Style',
      safe: true,
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Arc', value: 'arc'),
        EnumOption(label: 'Bar', value: 'bar'),
      ]),
  PropertyMeta(
      key: 'orientation',
      label: 'Orientation',
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Horizontal', value: 'horizontal'),
        EnumOption(label: 'Vertical', value: 'vertical'),
      ]),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _appgrid = [
  PropertyMeta(
      key: 'apps',
      label: 'Apps list',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'columns',
      label: 'Columns',
      safe: true,
      category: PropertyCategory.visuals,
      min: 1,
      max: 6,
      step: 1),
  PropertyMeta(
      key: 'iconSize',
      label: 'Icon size',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showLabels',
      label: 'Show labels',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _statusbar = [
  PropertyMeta(
      key: 'time',
      label: 'Time',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'battery',
      label: 'Battery level',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'signal',
      label: 'Signal level',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'showTime',
      label: 'Show time',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showBattery',
      label: 'Show battery',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showSignal',
      label: 'Show signal',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _climate = [
  PropertyMeta(
      key: 'temperature',
      label: 'Temperature',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'targetTemp',
      label: 'Target temperature',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'fanSpeed',
      label: 'Fan speed',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'mode',
      label: 'Mode',
      safe: true,
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Auto', value: 'auto'),
        EnumOption(label: 'Cooling', value: 'cool'),
        EnumOption(label: 'Heating', value: 'heat'),
        EnumOption(label: 'Defrost', value: 'defrost'),
      ]),
  PropertyMeta(
      key: 'unit',
      label: 'Unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _car_viz = [
  PropertyMeta(
      key: 'laneLeft',
      label: 'Left lane warning',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'laneRight',
      label: 'Right lane warning',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'carAhead',
      label: 'Car ahead',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'doorLeft',
      label: 'Left door open',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'doorRight',
      label: 'Right door open',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'showRing',
      label: 'Show Pod Ring',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showLabels',
      label: 'Show Pod Labels',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _map = [
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'eta',
      label: 'ETA',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'distance',
      label: 'Distance',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'nextTurn',
      label: 'Next turn',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'showMapGraphic',
      label: 'Show map graphic',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'mapStyle',
      label: 'Map style',
      safe: true,
      category: PropertyCategory.visuals,
      options: [
        EnumOption(label: 'Decorative (vector)', value: 'vector'),
        EnumOption(label: 'Live map (OpenStreetMap)', value: 'osm'),
        EnumOption(label: 'Decorative (satellite look)', value: 'satellite'),
      ]),
  PropertyMeta(
      key: 'lat',
      label: 'Latitude',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'lon',
      label: 'Longitude',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'zoom',
      label: 'Zoom level',
      category: PropertyCategory.visuals,
      min: 1,
      max: 19,
      step: 1),
  PropertyMeta(
      key: 'heading',
      label: 'Heading',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _gps = [
  PropertyMeta(
      key: 'speed',
      label: 'Speed binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'altitude',
      label: 'Altitude binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'lat',
      label: 'Latitude binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'lon',
      label: 'Longitude binding',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'unit',
      label: 'Speed unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showCoordinates',
      label: 'Show coordinates',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 12,
      max: 80,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 12,
      step: 1),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 32,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.visuals,
      min: 0,
      max: 1,
      step: 0.05),
];

const List<PropertyMeta> _gear_selector = [
  PropertyMeta(
      key: 'currentGear',
      label: 'Current gear',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'gears',
      label: 'Gear list',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'color',
      label: 'Colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'activeColor',
      label: 'Active colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'inactiveColor',
      label: 'Inactive colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _battery_range = [
  PropertyMeta(
      key: 'batteryLevel',
      label: 'Battery level (0-1)',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'range',
      label: 'Range',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'temperature',
      label: 'Temperature',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'color',
      label: 'Bar colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'textColor',
      label: 'Text colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accentColor',
      label: 'Accent colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'showRange',
      label: 'Show range',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'showTemperature',
      label: 'Show temperature',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'unit',
      label: 'Range unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'tempUnit',
      label: 'Temp unit',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'fontFamily',
      label: 'Font family',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'fontWeight',
      label: 'Font weight',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'letterSpacing',
      label: 'Letter spacing',
      category: PropertyCategory.fontsAndColors,
      min: -2,
      max: 10,
      step: 0.5),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
];

const List<PropertyMeta> _power_flow = [
  PropertyMeta(
      key: 'power',
      label: 'Power',
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'maxPower',
      label: 'Max power',
      safe: true,
      category: PropertyCategory.dataBindings),
  PropertyMeta(
      key: 'color',
      label: 'Bar colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'accent',
      label: 'Accent colour',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'label',
      label: 'Label',
      safe: true,
      category: PropertyCategory.visuals),
  PropertyMeta(
      key: 'barWidth',
      label: 'Bar width',
      category: PropertyCategory.visuals,
      min: 1,
      max: 100,
      step: 1),
  PropertyMeta(
      key: 'barHeight',
      label: 'Bar height',
      category: PropertyCategory.visuals,
      min: 1,
      max: 500,
      step: 1),
  PropertyMeta(
      key: 'backgroundColor',
      label: 'Background',
      safe: true,
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'borderRadius',
      label: 'Corner radius',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 48,
      step: 1),
  PropertyMeta(
      key: 'fontSize',
      label: 'Font size',
      safe: true,
      category: PropertyCategory.fontsAndColors,
      min: 8,
      max: 96,
      step: 1),
  PropertyMeta(
      key: 'borderWidth',
      label: 'Border width',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 20,
      step: 0.5),
  PropertyMeta(
      key: 'borderColor',
      label: 'Border colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowColor',
      label: 'Shadow colour',
      category: PropertyCategory.fontsAndColors),
  PropertyMeta(
      key: 'shadowBlur',
      label: 'Shadow blur',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 40,
      step: 1),
  PropertyMeta(
      key: 'shadowOffsetY',
      label: 'Shadow offset Y',
      category: PropertyCategory.layoutAndSpacing,
      min: -20,
      max: 20,
      step: 1),
  PropertyMeta(
      key: 'opacity',
      label: 'Opacity',
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 1,
      step: 0.05),
  PropertyMeta(
      key: 'padding',
      label: 'Padding',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 0,
      max: 64,
      step: 1),
  PropertyMeta(
      key: 'width',
      label: 'Width',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'height',
      label: 'Height',
      safe: true,
      category: PropertyCategory.layoutAndSpacing,
      min: 50,
      max: 800,
      step: 10),
  PropertyMeta(
      key: 'visible',
      label: 'Visible',
      safe: true,
      category: PropertyCategory.layoutAndSpacing),
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
  'digitalspeed': _digitalspeed,
  'music': _music,
  'tripstats': _tripstats,
  'power': _power,
  'warnings': _warnings,
  'minigauge': _minigauge,
  'appgrid': _appgrid,
  'statusbar': _statusbar,
  'climate': _climate,
  'car_viz': _car_viz,
  'map': _map,
  'gear_selector': _gear_selector,
  'gps': _gps,
  'battery_range': _battery_range,
  'power_flow': _power_flow,
};

List<PropertyMeta> allProperties(String widgetKind) {
  return (propertyManifest[widgetKind] ?? const <PropertyMeta>[]).toList();
}

Map<PropertyCategory, List<PropertyMeta>> _groupPropertiesByCategory(
  String widgetKind,
) {
  final props = allProperties(widgetKind);
  final map = <PropertyCategory, List<PropertyMeta>>{
    for (final cat in PropertyCategory.values) cat: [],
  };
  for (final meta in props) {
    map[meta.category]?.add(meta);
  }
  return map;
}

Map<PropertyCategory, List<PropertyMeta>> categorizedProperties(
        String widgetKind) =>
    _groupPropertiesByCategory(widgetKind);

Map<PropertyCategory, List<PropertyMeta>> propertiesByCategory(
        String widgetKind) =>
    _groupPropertiesByCategory(widgetKind);

List<PropertyMeta> getPropertiesByCategory(
  String widgetKind,
  PropertyCategory category,
) {
  return (_groupPropertiesByCategory(widgetKind)[category] ??
      const <PropertyMeta>[]);
}
