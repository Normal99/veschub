part of 'studio_editor.dart';

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

/// Groups widget kinds into palette sections, in display order. A kind not
/// listed here still shows up, under a trailing "Other" section — this is a
/// display grouping only and never hides a widget kind.
const Map<String, List<String>> _paletteCategories = {
  'Gauges & Meters': [
    'gauge',
    'minigauge',
    'digitalspeed',
    'power',
    'power_flow'
  ],
  'Text & Data': ['text', 'status', 'tripstats', 'warnings'],
  'Charts': ['bar', 'chart'],
  'Car Status': ['car_viz', 'gear_selector', 'battery_range', 'climate', 'map'],
  'Media & Controls': ['music', 'appgrid', 'statusbar'],
  'Custom': ['image', 'web', 'paint'],
};

/// The drag-drop widget palette: searchable, grouped into categories.
class _WidgetPalette extends ConsumerStatefulWidget {
  const _WidgetPalette();

  static Binding T(String key) => Binding.telemetry(key: key);
  static Binding L(Object v) => Binding.literal(value: v);

  /// Per-template props — shape the widget itself, not just its container.
  /// Each template has a name, icon, and a map of properties that make it
  /// visually distinct (dial geometry, needle, ticks, colour scheme).

  static final _templates = <String,
      List<({String name, IconData icon, Map<String, Binding> props})>>{
    'gauge': [
      (
        name: 'Speedometer',
        icon: Icons.speed,
        props: _dial(
            sweep: 270,
            ticks: 10,
            arc: 10,
            colour: 0xFFFFFFFF,
            accent: 0xFF888888,
            unit: 'km/h',
            fSize: 48,
            w: 300,
            h: 300),
      ),
      (
        name: 'Tachometer',
        icon: Icons.show_chart,
        props: _dial(
            sweep: 270,
            ticks: 8,
            arc: 8,
            colour: 0xFFEF5350,
            accent: 0xFFFF8A80,
            unit: 'RPM',
            fSize: 36,
            w: 280,
            h: 280),
      ),
      (
        name: 'Battery %',
        icon: Icons.battery_full,
        props: _dial(
            sweep: 180,
            ticks: 5,
            arc: 8,
            colour: 0xFF66BB6A,
            accent: 0xFF4FC3F7,
            unit: '%',
            fSize: 40,
            w: 240,
            h: 240),
      ),
      (
        name: 'Tesla Style',
        icon: Icons.electric_car,
        props: {
          'value': T('speed'),
          'min': L(0),
          'max': L(320),
          'needleStyle': L('arc'),
          'sweepAngle': L(360),
          'startAngle': L(270),
          'tickCount': L(16),
          'arcWidth': L(3),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF666666),
          'showCenterText': L(true),
          'centerValue': T('speed'),
          'centerUnit': L('km/h'),
          'showTickLabels': L(true),
          'fontSize': L(80),
          'backgroundColor': L(0x00000000),
          'borderRadius': L(0),
          'padding': L(24),
          'width': L(320),
          'height': L(320),
        },
      ),
      (
        name: 'BMW Amber',
        icon: Icons.directions_car,
        props: {
          'value': T('speed'),
          'min': L(0),
          'max': L(260),
          'needleStyle': L('needle'),
          'sweepAngle': L(270),
          'startAngle': L(135),
          'tickCount': L(13),
          'arcWidth': L(8),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFFFFA500),
          'label': L('km/h'),
          'showCenterText': L(true),
          'centerValue': T('speed'),
          'showTickLabels': L(true),
          'fontSize': L(48),
          'backgroundColor': L(0xFF0A0A0A),
          'borderRadius': L(120),
          'padding': L(16),
          'width': L(320),
          'height': L(320),
        },
      ),
      (
        name: 'Audi Sport',
        icon: Icons.auto_awesome,
        props: {
          'value': T('erpm'),
          'min': L(0),
          'max': L(8000),
          'needleStyle': L('needle'),
          'sweepAngle': L(270),
          'startAngle': L(135),
          'tickCount': L(8),
          'arcWidth': L(6),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF4488FF),
          'label': L('1/min x1000'),
          'showCenterText': L(true),
          'centerValue': T('erpm'),
          'centerUnit': L('rpm'),
          'showTickLabels': L(true),
          'redlineStart': L(0.82),
          'redlineColor': L(0xFFFF0000),
          'fontSize': L(48),
          'backgroundColor': L(0xFF050510),
          'borderRadius': L(12),
          'padding': L(16),
          'width': L(320),
          'height': L(320),
        },
      ),
      (
        name: 'Porsche Green',
        icon: Icons.sports_motorsports,
        props: {
          'value': T('speed'),
          'min': L(0),
          'max': L(340),
          'needleStyle': L('needle'),
          'sweepAngle': L(270),
          'startAngle': L(135),
          'tickCount': L(12),
          'arcWidth': L(8),
          'color': L(0xFF00CC66),
          'accent': L(0xFF888888),
          'label': L('mph'),
          'showCenterText': L(true),
          'centerValue': T('speed'),
          'centerUnit': L('mph'),
          'showTickLabels': L(true),
          'fontSize': L(56),
          'backgroundColor': L(0xFF0A0A0A),
          'borderRadius': L(120),
          'padding': L(16),
          'width': L(320),
          'height': L(320),
        },
      ),
      (
        name: 'Minimal Arc',
        icon: Icons.circle_outlined,
        props: _dial(
            sweep: 180,
            ticks: 5,
            arc: 4,
            colour: 0xFFFFFFFF,
            accent: 0x66333333,
            unit: '',
            fSize: 36,
            w: 240,
            h: 180),
      ),
    ],
    'bar': [
      (
        // A genuinely undecorated bar — no radius, no padding, no card
        // background — the "just the fill, nothing else" option.
        name: 'Minimal',
        icon: Icons.exposure_zero,
        props: {
          'value': T('duty'),
          'min': L(0),
          'max': L(1),
          'color': L(0xFFFFFFFF),
          'backgroundColor': L(0x22FFFFFF),
          'borderRadius': L(0),
          'padding': L(0),
          'width': L(300),
          'height': L(24)
        },
      ),
      (
        name: 'Horizontal',
        icon: Icons.bar_chart,
        props: {
          'value': T('duty'),
          'min': L(0),
          'max': L(1),
          'color': L(0xFF4FC3F7),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(6),
          'padding': L(8),
          'width': L(300),
          'height': L(80)
        },
      ),
      (
        name: 'Vertical',
        icon: Icons.bar_chart,
        props: {
          'value': T('duty'),
          'min': L(0),
          'max': L(1),
          'color': L(0xFF66BB6A),
          'orientation': L('vertical'),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(6),
          'padding': L(8),
          'width': L(80),
          'height': L(300)
        },
      ),
      (
        name: 'Thin',
        icon: Icons.bar_chart,
        props: {
          'value': T('current.motor'),
          'min': L(0),
          'max': L(100),
          'color': L(0xFFEF5350),
          'backgroundColor': L(0x00000000),
          'borderRadius': L(2),
          'padding': L(2),
          'width': L(300),
          'height': L(60)
        },
      ),
      (
        name: 'Wide Card',
        icon: Icons.bar_chart,
        props: {
          'value': T('duty'),
          'min': L(0),
          'max': L(1),
          'color': L(0xFFFF9800),
          'backgroundColor': L(0xFF1E1E2E),
          'borderRadius': L(12),
          'borderWidth': L(1),
          'borderColor': L(0x33FFFFFF),
          'padding': L(16),
          'width': L(380),
          'height': L(100)
        },
      ),
    ],
    'text': [
      (
        // A SimHub-style "just the number" option: no card, no label, no
        // background chrome — for a dashboard that only shows the 2-3
        // values someone actually cares about. See ROADMAP.md's note on
        // needing genuinely minimal starters alongside the styled presets.
        name: 'Minimal',
        icon: Icons.exposure_zero,
        props: {
          'value': T('v_in'),
          'unit': L('V'),
          'fontSize': L(48),
          'color': L(0xFFFFFFFF),
          'backgroundColor': L(0x00000000),
          'padding': L(4),
          'width': L(160),
          'height': L(70)
        },
      ),
      (
        name: 'Sans',
        icon: Icons.text_fields,
        props: {
          'value': T('v_in'),
          'label': L('Voltage'),
          'unit': L('V'),
          'fontSize': L(40),
          'color': L(0xFFFFFFFF),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'padding': L(10),
          'width': L(200),
          'height': L(100)
        },
      ),
      (
        name: 'Mono',
        icon: Icons.text_fields,
        props: {
          'value': T('erpm'),
          'label': L('RPM'),
          'fontSize': L(48),
          'fontWeight': L('bold'),
          'color': L(0xFF4FC3F7),
          'backgroundColor': L(0x00000000),
          'padding': L(8),
          'width': L(220),
          'height': L(100)
        },
      ),
      (
        name: 'Compact',
        icon: Icons.text_fields,
        props: {
          'value': T('current.motor'),
          'label': L('Motor'),
          'unit': L('A'),
          'fontSize': L(24),
          'color': L(0xFF66BB6A),
          'backgroundColor': L(0xFF1A1A2A),
          'borderRadius': L(6),
          'padding': L(6),
          'width': L(160),
          'height': L(70)
        },
      ),
    ],
    'chart': [
      (
        name: 'Line Chart',
        icon: Icons.show_chart,
        props: {
          'value': T('erpm'),
          'min': L(0),
          'max': L(30000),
          'label': L('RPM'),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'lineWidth': L(2),
          'smoothCurve': L(true),
          'padding': L(8)
        },
      ),
      (
        name: 'Area Chart',
        icon: Icons.show_chart,
        props: {
          'value': T('current.motor'),
          'min': L(0),
          'max': L(100),
          'label': L('Motor A'),
          'color': L(0xFF66BB6A),
          'backgroundColor': L(0xFF0D0D1A),
          'borderRadius': L(8),
          'fillArea': L(true),
          'fillColor': L(0x1166BB6A),
          'lineWidth': L(1.5),
          'padding': L(8)
        },
      ),
      (
        name: 'Bare Chart',
        icon: Icons.show_chart,
        props: {
          'value': T('erpm'),
          'min': L(0),
          'max': L(30000),
          'backgroundColor': L(0x00000000),
          'showGrid': L(false),
          'lineWidth': L(3),
          'borderRadius': L(0),
          'padding': L(0)
        },
      ),
    ],
    'status': [
      (
        name: 'Pill',
        icon: Icons.warning,
        props: {
          'fault': T('fault'),
          'backgroundColor': L(0xFF1A1A2E),
          'borderRadius': L(20),
          'fontSize': L(14),
          'padding': L(10)
        },
      ),
      (
        name: 'Inline',
        icon: Icons.warning,
        props: {
          'fault': T('fault'),
          'backgroundColor': L(0x00000000),
          'borderRadius': L(4),
          'fontSize': L(12),
          'padding': L(4)
        },
      ),
    ],
    'image': [
      (
        name: 'Rounded',
        icon: Icons.image,
        props: {
          'src': L('assets/images/placeholder.png'),
          'borderRadius': L(12),
          'borderWidth': L(1),
          'borderColor': L(0x44FFFFFF)
        },
      ),
      (
        name: 'Shadowed',
        icon: Icons.image,
        props: {
          'src': L('assets/images/placeholder.png'),
          'borderRadius': L(8),
          'shadowBlur': L(8),
          'shadowColor': L(0x44000000),
          'shadowOffsetY': L(4)
        },
      ),
    ],
    'web': [
      (
        name: 'Page',
        icon: Icons.public,
        props: {
          'url': L('https://example.com'),
          'title': L('Live page'),
          'borderRadius': L(8),
          'padding': L(4)
        },
      ),
    ],
    'paint': [
      (
        name: 'Custom',
        icon: Icons.brush,
        // A paint widget with an empty program renders nothing at all —
        // ship the same starter program used by the bare-default fallback
        // so dropping this from the palette gives immediate visual
        // feedback instead of an invisible box.
        props: {
          'program': L(_samplePaintProgram.toJson()),
        },
      ),
    ],
    'digitalspeed': [
      (
        name: 'Tesla Style',
        icon: Icons.speed,
        props: {
          'value': T('erpm'),
          'unit': L('km/h'),
          'fontSize': L(72),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'showUnit': L(true),
          'backgroundColor': L(0xFF000000),
          'borderRadius': L(0),
          'padding': L(16),
          'fontWeight': L('w200'),
          'width': L(280),
          'height': L(140)
        },
      ),
      (
        name: 'Compact',
        icon: Icons.speed,
        props: {
          'value': T('erpm'),
          'unit': L('mph'),
          'fontSize': L(48),
          'color': L(0xFF4FC3F7),
          'accent': L(0xFF666666),
          'showUnit': L(true),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'padding': L(12),
          'width': L(240),
          'height': L(110)
        },
      ),
      (
        name: 'With Sub',
        icon: Icons.speed,
        props: {
          'value': T('erpm'),
          'unit': L('km/h'),
          'fontSize': L(64),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'showUnit': L(true),
          'subLabel': L('Range'),
          'subValue': T('battery_pct'),
          'backgroundColor': L(0xFF0A0A0A),
          'borderRadius': L(0),
          'padding': L(16),
          'width': L(260),
          'height': L(160)
        },
      ),
    ],
    'music': [
      (
        name: 'Player',
        icon: Icons.music_note,
        props: {
          'title': L('Track Name'),
          'artist': L('Artist'),
          'progress': L(30),
          'duration': L(180),
          'showControls': L(true),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'albumColor': L(0xFF333333),
          'backgroundColor': L(0xFF1A1A2E),
          'borderRadius': L(12),
          'padding': L(12)
        },
      ),
      (
        name: 'Mini',
        icon: Icons.music_note,
        props: {
          'title': L('Now Playing'),
          'artist': L('Artist'),
          'showControls': L(false),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'albumColor': L(0xFF444444),
          'backgroundColor': L(0xFF0D0D1A),
          'borderRadius': L(8),
          'padding': L(8)
        },
      ),
    ],
    'tripstats': [
      (
        name: 'Trip Info',
        icon: Icons.info_outline,
        props: {
          'label1': L('Distance'),
          'value1': T('trip_distance'),
          'unit1': L('km'),
          'label2': L('Time'),
          'value2': T('trip_time'),
          'unit2': L('min'),
          'label3': L('Avg Speed'),
          'value3': T('avg_speed'),
          'unit3': L('km/h'),
          'label4': L('Energy'),
          'value4': T('energy_used'),
          'unit4': L('Wh'),
          'columns': L(2),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'fontSize': L(20),
          'padding': L(12),
          'width': L(300),
          'height': L(200)
        },
      ),
      (
        name: 'Compact',
        icon: Icons.info_outline,
        props: {
          'label1': L('ODO'),
          'value1': T('odometer'),
          'unit1': L('km'),
          'label2': L('Trip'),
          'value2': T('trip_distance'),
          'unit2': L('km'),
          'label3': L('Avg'),
          'value3': T('avg_speed'),
          'unit3': L('km/h'),
          'columns': L(2),
          'color': L(0xFF4FC3F7),
          'accent': L(0xFF666666),
          'backgroundColor': L(0xFF0A0A14),
          'borderRadius': L(6),
          'fontSize': L(16),
          'padding': L(8),
          'width': L(280),
          'height': L(140)
        },
      ),
    ],
    'power': [
      (
        name: 'Power Meter',
        icon: Icons.bolt,
        props: {
          'power': T('power'),
          'maxPower': L(10000),
          'color': L(0xFF00FF88),
          'regenColor': L(0xFF4488FF),
          'accent': L(0xFF888888),
          'showBars': L(true),
          'label': L('Power'),
          'backgroundColor': L(0xFF0D0D1A),
          'borderRadius': L(8),
          'fontSize': L(28),
          'padding': L(12)
        },
      ),
      (
        name: 'Simple',
        icon: Icons.bolt,
        props: {
          'power': T('power'),
          'maxPower': L(5000),
          'color': L(0xFFFF9800),
          'regenColor': L(0xFF4FC3F7),
          'accent': L(0xFF666666),
          'showBars': L(false),
          'label': L('Watts'),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(6),
          'fontSize': L(24),
          'padding': L(8)
        },
      ),
    ],
    'warnings': [
      (
        name: 'Warning Icons',
        icon: Icons.warning,
        props: {
          'activeWarnings': L('temp,battery'),
          'color': L(0xFFFF4444),
          'warningColor': L(0xFFFFAA00),
          'infoColor': L(0xFF4488FF),
          'iconSize': L(24),
          'backgroundColor': L(0xFF1A1A2E),
          'borderRadius': L(8),
          'padding': L(8)
        },
      ),
      (
        name: 'Status',
        icon: Icons.check_circle,
        props: {
          'activeWarnings': L(''),
          'color': L(0xFF00CC66),
          'warningColor': L(0xFFFFAA00),
          'infoColor': L(0xFF4488FF),
          'iconSize': L(20),
          'backgroundColor': L(0x00000000),
          'borderRadius': L(0),
          'padding': L(4)
        },
      ),
    ],
    'minigauge': [
      (
        name: 'Battery',
        icon: Icons.battery_full,
        props: {
          'value': T('battery_pct'),
          'min': L(0),
          'max': L(100),
          'label': L('Battery'),
          'unit': L('%'),
          'icon': L('battery'),
          'style': L('arc'),
          'color': L(0xFF00CC66),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'fontSize': L(16),
          'padding': L(8)
        },
      ),
      (
        name: 'Temp Bar',
        icon: Icons.thermostat,
        props: {
          'value': T('temp.mosfet'),
          'min': L(0),
          'max': L(100),
          'label': L('Temp'),
          'unit': L('°C'),
          'icon': L('temp'),
          'style': L('bar'),
          'color': L(0xFFFF5722),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF1A1A2E),
          'borderRadius': L(6),
          'fontSize': L(14),
          'padding': L(6)
        },
      ),
      (
        name: 'Fuel',
        icon: Icons.local_gas_station,
        props: {
          'value': T('battery_pct'),
          'min': L(0),
          'max': L(100),
          'label': L('Fuel'),
          'unit': L('%'),
          'icon': L('fuel'),
          'style': L('arc'),
          'color': L(0xFFFF9800),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF0D0D1A),
          'borderRadius': L(8),
          'fontSize': L(14),
          'padding': L(8)
        },
      ),
    ],
    'appgrid': [
      (
        name: 'CarPlay',
        icon: Icons.apps,
        props: {
          'apps':
              L('phone,music,maps,messages,settings,weather,clock,calculator'),
          'columns': L(4),
          'iconSize': L(28),
          'showLabels': L(true),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF000000),
          'borderRadius': L(0),
          'padding': L(16)
        },
      ),
      (
        name: 'Compact',
        icon: Icons.apps,
        props: {
          'apps': L('phone,music,maps,settings'),
          'columns': L(2),
          'iconSize': L(24),
          'showLabels': L(false),
          'color': L(0xFF4FC3F7),
          'accent': L(0xFF666666),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'padding': L(12)
        },
      ),
    ],
    'statusbar': [
      (
        name: 'Top Bar',
        icon: Icons.bar_chart,
        props: {
          'time': L('12:34'),
          'battery': L(0.85),
          'signal': L(0.75),
          'showTime': L(true),
          'showBattery': L(true),
          'showSignal': L(true),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF000000),
          'borderRadius': L(0),
          'fontSize': L(13),
          'padding': L(8)
        },
      ),
      (
        name: 'Minimal',
        icon: Icons.bar_chart,
        props: {
          'time': L(''),
          'battery': L(0.5),
          'signal': L(0.5),
          'showTime': L(false),
          'showBattery': L(true),
          'showSignal': L(false),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'backgroundColor': L(0x00000000),
          'borderRadius': L(0),
          'fontSize': L(12),
          'padding': L(4)
        },
      ),
    ],
    'climate': [
      (
        name: 'Temperature',
        icon: Icons.thermostat,
        props: {
          'temperature': L(22),
          'targetTemp': L(23),
          'fanSpeed': L(0.5),
          'mode': L('auto'),
          'unit': L('°C'),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF888888),
          'backgroundColor': L(0xFF1A1A2E),
          'borderRadius': L(12),
          'fontSize': L(32),
          'padding': L(16)
        },
      ),
      (
        name: 'Compact',
        icon: Icons.thermostat,
        props: {
          'temperature': L(20),
          'mode': L('cool'),
          'unit': L('°F'),
          'color': L(0xFF4FC3F7),
          'accent': L(0xFF666666),
          'backgroundColor': L(0xFF0D0D1A),
          'borderRadius': L(8),
          'fontSize': L(24),
          'padding': L(12)
        },
      ),
    ],
    'car_viz': [
      (
        name: 'Lane Assist',
        icon: Icons.directions_car,
        props: {
          'laneLeft': L(false),
          'laneRight': L(false),
          'carAhead': L(false),
          'label': L('Lane Keep'),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF4488FF),
          'backgroundColor': L(0xFF0A0A14),
          'borderRadius': L(8),
          'padding': L(8)
        },
      ),
    ],
    'map': [
      (
        name: 'Navigation',
        icon: Icons.map,
        props: {
          'label': L('Navigation'),
          'eta': L('15 min'),
          'distance': L('8.2 km'),
          'nextTurn': L('Turn right'),
          'color': L(0xFFFFFFFF),
          'accent': L(0xFF4488FF),
          'backgroundColor': L(0xFF111122),
          'borderRadius': L(8),
          'padding': L(8),
          'width': L(400),
          'height': L(300)
        },
      ),
    ],
    'battery_range': [
      (
        name: 'Battery Range',
        icon: Icons.battery_charging_full,
        props: {
          'batteryLevel': L(0.8),
          'range': T('range'),
          'temperature': T('temp.mosfet'),
          'color': L(0xFF00CC66),
          'textColor': L(0xFFFFFFFF),
          'accentColor': L(0xFF888888),
          'showRange': L(true),
          'showTemperature': L(true),
          'unit': L('km'),
          'tempUnit': L('°C'),
          'fontSize': L(24),
          'backgroundColor': L(0xFF0A0A0A),
          'borderRadius': L(8),
          'padding': L(12),
          'width': L(400),
          'height': L(80)
        },
      ),
    ],
    'power_flow': [
      (
        name: 'kW Bar',
        icon: Icons.bolt,
        props: {
          'power': T('power'),
          'maxPower': L(200),
          'color': L(0xFFFF9800),
          'accent': L(0xFF888888),
          'label': L('kW'),
          'barWidth': L(80),
          'barHeight': L(6),
          'fontSize': L(18),
          'backgroundColor': L(0x00000000),
          'padding': L(8),
          'width': L(200),
          'height': L(50)
        },
      ),
    ],
    'gear_selector': [
      (
        name: 'PRND',
        icon: Icons.swap_vert,
        props: {
          'currentGear': L('P'),
          'gears': L('P,R,N,D'),
          'activeColor': L(0xFFFFFFFF),
          'inactiveColor': L(0xFF666666),
          'fontSize': L(32),
          'backgroundColor': L(0x00000000),
          'padding': L(8),
          'width': L(240),
          'height': L(60)
        },
      ),
    ],
  };

  /// Build a modern gauge template with center text, tick labels, and proper sizing.
  static Map<String, Binding> _dial({
    required double sweep,
    required int ticks,
    required double arc,
    required int colour,
    required int accent,
    required String unit,
    required double fSize,
    required double w,
    required double h,
  }) =>
      {
        'value': T('erpm'),
        'min': L(0),
        'max': L(30000),
        'needleStyle': L('arc'),
        'sweepAngle': L(sweep),
        'startAngle': L(135),
        'tickCount': L(ticks),
        'arcWidth': L(arc),
        'color': L(colour),
        'accent': L(accent),
        'label': L(''),
        'showCenterText': L(true),
        'centerValue': T('erpm'),
        'centerUnit': L(unit),
        'showTickLabels': L(true),
        'fontSize': L(fSize),
        'backgroundColor': L(0x00000000),
        'borderRadius': L(0),
        'padding': L(16),
        'width': L(w),
        'height': L(h),
      };

  // Canonical per-kind icon lives in widgets_library (kindIcon) so the
  // palette, layer panel, and anywhere else that lists kinds can't drift
  // out of sync with each other.
  static IconData _kindIcon(String kind) => kindIcon(kind);

  @override
  ConsumerState<_WidgetPalette> createState() => _WidgetPaletteState();
}

class _WidgetPaletteState extends ConsumerState<_WidgetPalette> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<({String name, IconData icon, Map<String, Binding> props})>
      _matchingTemplates(String kind) {
    final tpls = _WidgetPalette._templates[kind] ?? const [];
    if (_query.isEmpty || kind.contains(_query)) return tpls;
    return tpls.where((t) => t.name.toLowerCase().contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allKinds = builtInWidgets.keys.toList();
    final searching = _query.isNotEmpty;

    final items = <Widget>[];
    if (searching) {
      final visibleKinds = allKinds
          .where((k) => k.contains(_query) || _matchingTemplates(k).isNotEmpty)
          .toList();
      for (final kind in visibleKinds) {
        items.add(_kindTile(kind, _matchingTemplates(kind), expanded: true));
      }
      if (visibleKinds.isEmpty) {
        items.add(Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No widgets match "$_query"',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ));
      }
    } else {
      var firstTileShown = false;
      final categorizedKinds = <String>{};
      for (final entry in _paletteCategories.entries) {
        final kindsInCategory = entry.value.where(allKinds.contains).toList();
        if (kindsInCategory.isEmpty) continue;
        items.add(_categoryHeader(context, entry.key));
        for (final kind in kindsInCategory) {
          categorizedKinds.add(kind);
          items.add(_kindTile(kind, _WidgetPalette._templates[kind] ?? const [],
              expanded: !firstTileShown));
          firstTileShown = true;
        }
      }
      final leftover =
          allKinds.where((k) => !categorizedKinds.contains(k)).toList();
      if (leftover.isNotEmpty) {
        items.add(_categoryHeader(context, 'Other'));
        for (final kind in leftover) {
          items.add(_kindTile(kind, _WidgetPalette._templates[kind] ?? const [],
              expanded: !firstTileShown));
          firstTileShown = true;
        }
      }
    }

    return Container(
      width: 200,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child:
                Text('Widgets', style: Theme.of(context).textTheme.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search widgets…',
                hintStyle: const TextStyle(fontSize: 12),
                prefixIcon: const Icon(Icons.search, size: 16),
                suffixIcon: searching
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        tooltip: 'Clear search',
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _query = '';
                        }),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: ListView(children: items)),
        ],
      ),
    );
  }

  Widget _categoryHeader(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );

  Widget _kindTile(
    String kind,
    List<({String name, IconData icon, Map<String, Binding> props})> tpls, {
    required bool expanded,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ExpansionTile(
        leading: Tooltip(
          message: kindDescription(kind),
          child: Icon(_WidgetPalette._kindIcon(kind), size: 20),
        ),
        title: Tooltip(
          message: kindDescription(kind),
          child: Text(kind.capitalize(), style: const TextStyle(fontSize: 13)),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
        initiallyExpanded: expanded,
        children: [
          for (final tpl in tpls)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Draggable<Map<String, dynamic>>(
                data: {'kind': kind, 'props': tpl.props},
                feedback: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(tpl.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child:
                      _PaletteTile(kind: kind, label: tpl.name, icon: tpl.icon),
                ),
                child:
                    _PaletteTile(kind: kind, label: tpl.name, icon: tpl.icon),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  final String kind;
  final String? label;
  final IconData? icon;
  const _PaletteTile({required this.kind, this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Drag onto the canvas to add.\n${kindDescription(kind)}',
      child: ListTile(
        leading: Icon(icon ?? Icons.widgets, size: 16),
        title: Text(label ?? kind, style: const TextStyle(fontSize: 11)),
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        minLeadingWidth: 24,
      ),
    );
  }
}
