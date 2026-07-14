/// Veschub built-in widget renderers shared by the studio (preview) and the
/// dashboard runtime. Each renderer consumes a [ResolvedProperties] map from
/// [dashboard_runtime] and paints itself; the runtime wraps each in a
/// `RepaintBoundary` so only dirty widgets repaint.
library;

import 'package:flutter/widgets.dart';

import 'package:dashboard_model/dashboard_model.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';

import 'widgets/bar_widget.dart';
import 'widgets/chart_widget.dart';
import 'widgets/gauge_widget.dart';
import 'widgets/image_widget.dart';
import 'widgets/status_widget.dart';
import 'widgets/text_widget.dart';
import 'widgets/web_widget.dart';

export 'src/format.dart';
export 'src/theme.dart';

/// Metadata for a built-in widget kind.
class WidgetKind {
  final String id;
  final CapabilityLevel level;
  final Widget Function(ResolvedProperties) render;

  const WidgetKind({
    required this.id,
    required this.level,
    required this.render,
  });
}

/// Registry of all built-in widget kinds, keyed by [WidgetKind.id].
final Map<String, WidgetKind> builtInWidgets = {
  'text': WidgetKind(
    id: 'text',
    level: CapabilityLevel.basic,
    render: (p) => TextWidget(properties: p),
  ),
  'bar': WidgetKind(
    id: 'bar',
    level: CapabilityLevel.basic,
    render: (p) => BarWidget(properties: p),
  ),
  'gauge': WidgetKind(
    id: 'gauge',
    level: CapabilityLevel.basic,
    render: (p) => GaugeWidget(properties: p),
  ),
  'status': WidgetKind(
    id: 'status',
    level: CapabilityLevel.basic,
    render: (p) => StatusWidget(properties: p),
  ),
  'chart': WidgetKind(
    id: 'chart',
    level: CapabilityLevel.advanced,
    render: (p) => ChartWidget(properties: p),
  ),
  'image': WidgetKind(
    id: 'image',
    level: CapabilityLevel.basic,
    render: (p) => ImageWidget(properties: p),
  ),
  'web': WidgetKind(
    id: 'web',
    level: CapabilityLevel.advanced,
    render: (p) => WebWidget(properties: p),
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
