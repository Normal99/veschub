/// Veschub built-in widget renderers shared by the studio (preview) and the
/// dashboard runtime. Each renderer consumes a [ResolvedProperties] map from
/// [dashboard_runtime] and paints itself; the runtime wraps each in a
/// `RepaintBoundary` so only dirty widgets repaint.
library;

import 'package:flutter/widgets.dart';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';

export 'src/kind_icons.dart';
export 'src/font_catalog.dart';
export 'src/property_descriptions.dart';

import 'widgets/appgrid_widget.dart';
import 'widgets/bar_widget.dart';
import 'widgets/battery_range_widget.dart';
import 'widgets/car_viz_widget.dart';
import 'widgets/chart_widget.dart';
import 'widgets/climate_widget.dart';
import 'widgets/digitalspeed_widget.dart';
import 'widgets/gauge_widget.dart';
import 'widgets/gear_selector_widget.dart';
import 'widgets/gps_widget.dart';
import 'widgets/image_widget.dart';
import 'widgets/map_widget.dart';
import 'widgets/minigauge_widget.dart';
import 'widgets/music_widget.dart';
import 'widgets/paint_widget.dart';
import 'widgets/power_flow_widget.dart';
import 'widgets/power_widget.dart';
import 'widgets/status_widget.dart';
import 'widgets/statusbar_widget.dart';
import 'widgets/text_widget.dart';
import 'widgets/tripstats_widget.dart';
import 'widgets/warnings_widget.dart';
import 'widgets/web_widget.dart';

export 'src/format.dart';
export 'src/property_manifest.dart';
export 'src/theme.dart';

export 'widgets/appgrid_widget.dart';
export 'widgets/bar_widget.dart';
export 'widgets/battery_range_widget.dart';
export 'widgets/car_viz_widget.dart';
export 'widgets/chart_widget.dart';
export 'widgets/climate_widget.dart';
export 'widgets/digitalspeed_widget.dart';
export 'widgets/gauge_widget.dart';
export 'widgets/gear_selector_widget.dart';
export 'widgets/gps_widget.dart';
export 'widgets/image_widget.dart';
export 'widgets/map_widget.dart';
export 'widgets/minigauge_widget.dart';
export 'widgets/music_widget.dart';
export 'widgets/paint_widget.dart';
export 'widgets/power_flow_widget.dart';
export 'widgets/power_widget.dart';
export 'widgets/status_widget.dart';
export 'widgets/statusbar_widget.dart';
export 'widgets/text_widget.dart';
export 'widgets/tripstats_widget.dart';
export 'widgets/warnings_widget.dart';
export 'widgets/web_widget.dart';

/// Metadata for a built-in widget kind.
class WidgetKind {
  final String id;
  final Widget Function(ResolvedProperties) render;

  const WidgetKind({
    required this.id,
    required this.render,
  });
}

/// Registry of all built-in widget kinds, keyed by [WidgetKind.id].
final Map<String, WidgetKind> builtInWidgets = {
  'text': WidgetKind(
    id: 'text',
    render: (p) => TextWidget(properties: p),
  ),
  'bar': WidgetKind(
    id: 'bar',
    render: (p) => BarWidget(properties: p),
  ),
  'gauge': WidgetKind(
    id: 'gauge',
    render: (p) => GaugeWidget(properties: p),
  ),
  'status': WidgetKind(
    id: 'status',
    render: (p) => StatusWidget(properties: p),
  ),
  'chart': WidgetKind(
    id: 'chart',
    render: (p) => ChartWidget(properties: p),
  ),
  'image': WidgetKind(
    id: 'image',
    render: (p) => ImageWidget(properties: p),
  ),
  'web': WidgetKind(
    id: 'web',
    render: (p) => WebWidget(properties: p),
  ),
  'paint': WidgetKind(
    id: 'paint',
    render: (p) => PaintWidget(properties: p),
  ),
  'digitalspeed': WidgetKind(
    id: 'digitalspeed',
    render: (p) => DigitalSpeedWidget(properties: p),
  ),
  'music': WidgetKind(
    id: 'music',
    render: (p) => MusicWidget(properties: p),
  ),
  'tripstats': WidgetKind(
    id: 'tripstats',
    render: (p) => TripStatsWidget(properties: p),
  ),
  'power': WidgetKind(
    id: 'power',
    render: (p) => PowerWidget(properties: p),
  ),
  'warnings': WidgetKind(
    id: 'warnings',
    render: (p) => WarningsWidget(properties: p),
  ),
  'minigauge': WidgetKind(
    id: 'minigauge',
    render: (p) => MiniGaugeWidget(properties: p),
  ),
  'appgrid': WidgetKind(
    id: 'appgrid',
    render: (p) => AppGridWidget(properties: p),
  ),
  'statusbar': WidgetKind(
    id: 'statusbar',
    render: (p) => StatusBarWidget(properties: p),
  ),
  'climate': WidgetKind(
    id: 'climate',
    render: (p) => ClimateWidget(properties: p),
  ),
  'car_viz': WidgetKind(
    id: 'car_viz',
    render: (p) => CarVizWidget(properties: p),
  ),
  'map': WidgetKind(
    id: 'map',
    render: (p) => MapWidget(properties: p),
  ),
  'gear_selector': WidgetKind(
    id: 'gear_selector',
    render: (p) => GearSelectorWidget(properties: p),
  ),
  'gps': WidgetKind(
    id: 'gps',
    render: (p) => GpsWidget(properties: p),
  ),
  'battery_range': WidgetKind(
    id: 'battery_range',
    render: (p) => BatteryRangeWidget(properties: p),
  ),
  'power_flow': WidgetKind(
    id: 'power_flow',
    render: (p) => PowerFlowWidget(properties: p),
  ),
};

/// Builds a widget tree for a single [WidgetInstance] given its resolved
/// properties. Returns a placeholder for unknown kinds.
Widget buildWidget(WidgetInstance instance, ResolvedProperties resolved) {
  final kind = builtInWidgets[instance.kind];
  if (kind == null) {
    return ColoredBox(
      color: const Color(0x44FF0000),
      child: Center(
        child: Text(
          'Unknown widget: ${instance.kind}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  return kind.render(resolved);
}
