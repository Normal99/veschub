/// The built-in template catalog.
///
/// Each template is a complete dashboard scaffold plus a restricted set of
/// knobs a Basic user may tweak (colours, units, limits) without entering
/// Canvas/Flow mode. The studio's Template-mode gallery renders these.
library;

import 'package:dashboard_model/dashboard_model.dart';

/// All built-in starter templates, ordered simplest → richest.
const List<DashboardTemplate> builtInTemplates = [
  Templates.minimal,
  Templates.performance,
  Templates.commuter,
  Templates.offRoad,
];

/// Template definitions.
class Templates {
  Templates._();

  /// A single big speed/RPM gauge — the simplest possible board.
  static const minimal = DashboardTemplate(
    id: 'minimal',
    name: 'Minimal',
    description: 'One large gauge — speed/RPM at a glance.',
    level: CapabilityLevel.basic,
    document: DashboardDocument(
      name: 'Minimal',
      canvas: CanvasSize(width: 800, height: 480),
      background: 0xFF000000,
      accent: 0xFFE0E0E0,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 250, 130],
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 30000),
            'label': Binding.literal(value: 'RPM'),
            'color': Binding.literal(value: 0xFF4FC3F7),
          },
        ),
      ],
    ),
    knobs: [
      TemplateKnob(
        widgetId: 'rpm',
        property: 'max',
        label: 'Max RPM',
        kind: KnobKind.number,
      ),
      TemplateKnob(
        widgetId: 'rpm',
        property: 'color',
        label: 'Gauge colour',
        kind: KnobKind.color,
      ),
      TemplateKnob(
        widgetId: 'rpm',
        property: 'label',
        label: 'Label',
        kind: KnobKind.text,
      ),
    ],
  );

  /// A performance board: RPM gauge + duty bar + voltage + current chart.
  static const performance = DashboardTemplate(
    id: 'performance',
    name: 'Performance',
    description: 'RPM, duty, voltage and a live current chart.',
    level: CapabilityLevel.basic,
    document: DashboardDocument(
      name: 'Performance',
      canvas: CanvasSize(width: 1280, height: 720),
      background: 0xFF0A0A0A,
      accent: 0xFFFFFFFF,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 60, 60],
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 40000),
            'label': Binding.literal(value: 'RPM'),
            'color': Binding.literal(value: 0xFF4FC3F7),
          },
        ),
        WidgetInstance(
          id: 'duty',
          kind: 'bar',
          transform: [1, 0, 0, 1, 680, 60],
          properties: {
            'value': Binding.telemetry(key: 'duty'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 1),
            'color': Binding.literal(value: 0xFFFFB74D),
          },
        ),
        WidgetInstance(
          id: 'vIn',
          kind: 'text',
          transform: [1, 0, 0, 1, 60, 480],
          properties: {
            'value': Binding.telemetry(key: 'v_in'),
            'label': Binding.literal(value: 'Pack'),
            'unit': Binding.literal(value: 'V'),
            'color': Binding.literal(value: 0xFFAED581),
          },
        ),
        WidgetInstance(
          id: 'current',
          kind: 'chart',
          transform: [1, 0, 0, 1, 680, 360],
          properties: {
            'value': Binding.telemetry(key: 'current.motor'),
            'min': Binding.literal(value: -50),
            'max': Binding.literal(value: 50),
            'label': Binding.literal(value: 'Current'),
            'color': Binding.literal(value: 0xFFEF5350),
          },
        ),
      ],
    ),
    knobs: [
      TemplateKnob(
        widgetId: 'rpm',
        property: 'max',
        label: 'Max RPM',
        kind: KnobKind.number,
      ),
      TemplateKnob(
        widgetId: 'rpm',
        property: 'color',
        label: 'RPM gauge colour',
        kind: KnobKind.color,
      ),
      TemplateKnob(
        widgetId: 'current',
        property: 'max',
        label: 'Chart max current',
        kind: KnobKind.number,
      ),
      TemplateKnob(
        widgetId: 'current',
        property: 'color',
        label: 'Chart colour',
        kind: KnobKind.color,
      ),
    ],
  );

  /// A commuter board: speed, battery %, temperature, fault status.
  static const commuter = DashboardTemplate(
    id: 'commuter',
    name: 'Commuter',
    description: 'Speed, battery, temps and fault status for daily rides.',
    level: CapabilityLevel.basic,
    document: DashboardDocument(
      name: 'Commuter',
      canvas: CanvasSize(width: 1280, height: 480),
      background: 0xFF101418,
      accent: 0xFFE0E0E0,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 40, 40],
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 25000),
            'label': Binding.literal(value: 'Speed'),
            'color': Binding.literal(value: 0xFF4FC3F7),
          },
        ),
        WidgetInstance(
          id: 'duty',
          kind: 'bar',
          transform: [1, 0, 0, 1, 660, 60],
          properties: {
            'value': Binding.telemetry(key: 'duty'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 1),
            'color': Binding.literal(value: 0xFFAED581),
          },
        ),
        WidgetInstance(
          id: 'tempMosfet',
          kind: 'text',
          transform: [1, 0, 0, 1, 660, 300],
          properties: {
            'value': Binding.telemetry(key: 'temp.mosfet'),
            'label': Binding.literal(value: 'FET'),
            'unit': Binding.literal(value: '°C'),
            'color': Binding.literal(value: 0xFFFFB74D),
          },
        ),
        WidgetInstance(
          id: 'fault',
          kind: 'status',
          transform: [1, 0, 0, 1, 40, 320],
          properties: {
            'fault': Binding.telemetry(key: 'fault'),
          },
        ),
      ],
    ),
    knobs: [
      TemplateKnob(
        widgetId: 'rpm',
        property: 'max',
        label: 'Max RPM',
        kind: KnobKind.number,
      ),
      TemplateKnob(
        widgetId: 'rpm',
        property: 'label',
        label: 'Speed label',
        kind: KnobKind.text,
      ),
    ],
  );

  /// An off-road board: big RPM, duty, dual temps, current chart, fault.
  static const offRoad = DashboardTemplate(
    id: 'offroad',
    name: 'Off-Road',
    description:
        'Full instrumentation — RPM, duty, dual temps, current, fault.',
    level: CapabilityLevel.basic,
    document: DashboardDocument(
      name: 'Off-Road',
      canvas: CanvasSize(width: 1280, height: 720),
      background: 0xFF1A1400,
      accent: 0xFFFFD54F,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 50, 50],
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 50000),
            'label': Binding.literal(value: 'RPM'),
            'color': Binding.literal(value: 0xFFFFD54F),
          },
        ),
        WidgetInstance(
          id: 'duty',
          kind: 'bar',
          transform: [1, 0, 0, 1, 680, 50],
          properties: {
            'value': Binding.telemetry(key: 'duty'),
            'min': Binding.literal(value: -1),
            'max': Binding.literal(value: 1),
            'color': Binding.literal(value: 0xFFFFB74D),
          },
        ),
        WidgetInstance(
          id: 'tempFet',
          kind: 'text',
          transform: [1, 0, 0, 1, 50, 430],
          properties: {
            'value': Binding.telemetry(key: 'temp.mosfet'),
            'label': Binding.literal(value: 'FET'),
            'unit': Binding.literal(value: '°C'),
            'color': Binding.literal(value: 0xFFEF5350),
          },
        ),
        WidgetInstance(
          id: 'tempMotor',
          kind: 'text',
          transform: [1, 0, 0, 1, 360, 430],
          properties: {
            'value': Binding.telemetry(key: 'temp.motor'),
            'label': Binding.literal(value: 'Motor'),
            'unit': Binding.literal(value: '°C'),
            'color': Binding.literal(value: 0xFFEF5350),
          },
        ),
        WidgetInstance(
          id: 'current',
          kind: 'chart',
          transform: [1, 0, 0, 1, 680, 340],
          properties: {
            'value': Binding.telemetry(key: 'current.motor'),
            'min': Binding.literal(value: -80),
            'max': Binding.literal(value: 80),
            'label': Binding.literal(value: 'Current'),
            'color': Binding.literal(value: 0xFF4FC3F7),
          },
        ),
        WidgetInstance(
          id: 'fault',
          kind: 'status',
          transform: [1, 0, 0, 1, 660, 620],
          properties: {
            'fault': Binding.telemetry(key: 'fault'),
          },
        ),
      ],
    ),
    knobs: [
      TemplateKnob(
        widgetId: 'rpm',
        property: 'max',
        label: 'Max RPM',
        kind: KnobKind.number,
      ),
      TemplateKnob(
        widgetId: 'current',
        property: 'max',
        label: 'Chart max current',
        kind: KnobKind.number,
      ),
      TemplateKnob(
        widgetId: 'rpm',
        property: 'color',
        label: 'RPM colour',
        kind: KnobKind.color,
      ),
    ],
  );
}
