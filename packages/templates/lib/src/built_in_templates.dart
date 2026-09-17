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
    category: 'Starter',
    document: DashboardDocument(
      name: 'Minimal',
      canvas: CanvasSize(width: 800, height: 480),
      background: 0xFF0A0E14,
      accent: 0xFF4FC3F7,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 200, 40],
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 30000),
            'label': Binding.literal(value: 'RPM'),
            'centerUnit': Binding.literal(value: 'RPM'),
            'showCenterText': Binding.literal(value: true),
            'showTickLabels': Binding.literal(value: true),
            'needleStyle': Binding.literal(value: 'needle'),
            'tickCount': Binding.literal(value: 10),
            'color': Binding.literal(value: 0xFF4FC3F7),
            'accent': Binding.literal(value: 0xFF0288D1),
            'backgroundColor': Binding.literal(value: 0),
            'width': Binding.literal(value: 400),
            'height': Binding.literal(value: 400),
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
    category: 'Starter',
    document: DashboardDocument(
      name: 'Performance',
      canvas: CanvasSize(width: 1280, height: 720),
      background: 0xFF0A0C10,
      accent: 0xFFFFFFFF,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 80, 80],
          properties: {
            'value': Binding.telemetry(key: 'erpm'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 40000),
            'label': Binding.literal(value: 'RPM'),
            'centerUnit': Binding.literal(value: 'RPM'),
            'showCenterText': Binding.literal(value: true),
            'showTickLabels': Binding.literal(value: true),
            'needleStyle': Binding.literal(value: 'needle'),
            'tickCount': Binding.literal(value: 10),
            'color': Binding.literal(value: 0xFF4FC3F7),
            'accent': Binding.literal(value: 0xFF0288D1),
            'backgroundColor': Binding.literal(value: 0),
            'width': Binding.literal(value: 480),
            'height': Binding.literal(value: 480),
          },
        ),
        WidgetInstance(
          id: 'duty',
          kind: 'bar',
          transform: [1, 0, 0, 1, 640, 80],
          properties: {
            'value': Binding.telemetry(key: 'duty'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 1),
            'label': Binding.literal(value: 'Duty Cycle'),
            'color': Binding.literal(value: 0xFFFFB74D),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 12),
            'padding': Binding.literal(value: 12),
            'width': Binding.literal(value: 560),
            'height': Binding.literal(value: 70),
          },
        ),
        WidgetInstance(
          id: 'vIn',
          kind: 'text',
          transform: [1, 0, 0, 1, 80, 590],
          properties: {
            'value': Binding.telemetry(key: 'v_in'),
            'label': Binding.literal(value: 'Pack Voltage'),
            'unit': Binding.literal(value: 'V'),
            'fontSize': Binding.literal(value: 28),
            'color': Binding.literal(value: 0xFFAED581),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 12),
            'padding': Binding.literal(value: 12),
            'width': Binding.literal(value: 480),
            'height': Binding.literal(value: 70),
          },
        ),
        WidgetInstance(
          id: 'current',
          kind: 'chart',
          transform: [1, 0, 0, 1, 640, 190],
          properties: {
            'value': Binding.telemetry(key: 'current.motor'),
            'min': Binding.literal(value: -50),
            'max': Binding.literal(value: 50),
            'label': Binding.literal(value: 'Motor Current (A)'),
            'color': Binding.literal(value: 0xFFEF5350),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 12),
            'padding': Binding.literal(value: 12),
            'width': Binding.literal(value: 560),
            'height': Binding.literal(value: 470),
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
    category: 'Starter',
    document: DashboardDocument(
      name: 'Commuter',
      canvas: CanvasSize(width: 1280, height: 480),
      background: 0xFF0F141C,
      accent: 0xFFE0E0E0,
      widgets: [
        WidgetInstance(
          id: 'rpm',
          kind: 'gauge',
          transform: [1, 0, 0, 1, 50, 40],
          properties: {
            'value': Binding.telemetry(key: 'speed'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 60),
            'label': Binding.literal(value: 'Speed'),
            'centerUnit': Binding.literal(value: 'km/h'),
            'showCenterText': Binding.literal(value: true),
            'showTickLabels': Binding.literal(value: true),
            'needleStyle': Binding.literal(value: 'needle'),
            'tickCount': Binding.literal(value: 12),
            'color': Binding.literal(value: 0xFF4FC3F7),
            'backgroundColor': Binding.literal(value: 0),
            'width': Binding.literal(value: 400),
            'height': Binding.literal(value: 400),
          },
        ),
        WidgetInstance(
          id: 'duty',
          kind: 'bar',
          transform: [1, 0, 0, 1, 500, 40],
          properties: {
            'value': Binding.telemetry(key: 'duty'),
            'min': Binding.literal(value: 0),
            'max': Binding.literal(value: 1),
            'label': Binding.literal(value: 'Duty Cycle'),
            'color': Binding.literal(value: 0xFFAED581),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 720),
            'height': Binding.literal(value: 60),
          },
        ),
        WidgetInstance(
          id: 'battery',
          kind: 'battery_range',
          transform: [1, 0, 0, 1, 500, 130],
          properties: {
            'batteryLevel': Binding.telemetry(key: 'battery_level'),
            'range': Binding.literal(value: 42),
            'temperature': Binding.telemetry(key: 'temp.mosfet'),
            'color': Binding.literal(value: 0xFF66BB6A),
            'textColor': Binding.literal(value: 0xFFFFFFFF),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 12),
            'width': Binding.literal(value: 720),
            'height': Binding.literal(value: 80),
          },
        ),
        WidgetInstance(
          id: 'tempMosfet',
          kind: 'text',
          transform: [1, 0, 0, 1, 500, 240],
          properties: {
            'value': Binding.telemetry(key: 'temp.mosfet'),
            'label': Binding.literal(value: 'FET Temp'),
            'unit': Binding.literal(value: '°C'),
            'fontSize': Binding.literal(value: 24),
            'color': Binding.literal(value: 0xFFFFB74D),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 720),
            'height': Binding.literal(value: 60),
          },
        ),
        WidgetInstance(
          id: 'fault',
          kind: 'status',
          transform: [1, 0, 0, 1, 500, 330],
          properties: {
            'fault': Binding.telemetry(key: 'fault'),
            'backgroundColor': Binding.literal(value: 0xFF1C212B),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 720),
            'height': Binding.literal(value: 110),
          },
        ),
      ],
    ),
    knobs: [
      TemplateKnob(
        widgetId: 'rpm',
        property: 'max',
        label: 'Max Speed',
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
    category: 'Starter',
    document: DashboardDocument(
      name: 'Off-Road',
      canvas: CanvasSize(width: 1280, height: 720),
      background: 0xFF18140B,
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
            'centerUnit': Binding.literal(value: 'RPM'),
            'showCenterText': Binding.literal(value: true),
            'showTickLabels': Binding.literal(value: true),
            'needleStyle': Binding.literal(value: 'needle'),
            'tickCount': Binding.literal(value: 10),
            'color': Binding.literal(value: 0xFFFFD54F),
            'backgroundColor': Binding.literal(value: 0),
            'width': Binding.literal(value: 520),
            'height': Binding.literal(value: 520),
          },
        ),
        WidgetInstance(
          id: 'duty',
          kind: 'bar',
          transform: [1, 0, 0, 1, 640, 50],
          properties: {
            'value': Binding.telemetry(key: 'duty'),
            'min': Binding.literal(value: -1),
            'max': Binding.literal(value: 1),
            'label': Binding.literal(value: 'Duty Cycle'),
            'color': Binding.literal(value: 0xFFFFB74D),
            'backgroundColor': Binding.literal(value: 0xFF262015),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 580),
            'height': Binding.literal(value: 60),
          },
        ),
        WidgetInstance(
          id: 'tempFet',
          kind: 'text',
          transform: [1, 0, 0, 1, 640, 130],
          properties: {
            'value': Binding.telemetry(key: 'temp.mosfet'),
            'label': Binding.literal(value: 'FET Temp'),
            'unit': Binding.literal(value: '°C'),
            'fontSize': Binding.literal(value: 22),
            'color': Binding.literal(value: 0xFFEF5350),
            'backgroundColor': Binding.literal(value: 0xFF262015),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 275),
            'height': Binding.literal(value: 70),
          },
        ),
        WidgetInstance(
          id: 'tempMotor',
          kind: 'text',
          transform: [1, 0, 0, 1, 945, 130],
          properties: {
            'value': Binding.telemetry(key: 'temp.motor'),
            'label': Binding.literal(value: 'Motor Temp'),
            'unit': Binding.literal(value: '°C'),
            'fontSize': Binding.literal(value: 22),
            'color': Binding.literal(value: 0xFFEF5350),
            'backgroundColor': Binding.literal(value: 0xFF262015),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 275),
            'height': Binding.literal(value: 70),
          },
        ),
        WidgetInstance(
          id: 'current',
          kind: 'chart',
          transform: [1, 0, 0, 1, 640, 220],
          properties: {
            'value': Binding.telemetry(key: 'current.motor'),
            'min': Binding.literal(value: -80),
            'max': Binding.literal(value: 80),
            'label': Binding.literal(value: 'Motor Current (A)'),
            'color': Binding.literal(value: 0xFF4FC3F7),
            'backgroundColor': Binding.literal(value: 0xFF262015),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 580),
            'height': Binding.literal(value: 350),
          },
        ),
        WidgetInstance(
          id: 'fault',
          kind: 'status',
          transform: [1, 0, 0, 1, 640, 590],
          properties: {
            'fault': Binding.telemetry(key: 'fault'),
            'backgroundColor': Binding.literal(value: 0xFF262015),
            'borderRadius': Binding.literal(value: 10),
            'padding': Binding.literal(value: 10),
            'width': Binding.literal(value: 580),
            'height': Binding.literal(value: 80),
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
