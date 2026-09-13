part of 'studio_editor.dart';

/// The canvas area with drag-drop acceptance.
class _CanvasArea extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CanvasArea> createState() => _CanvasAreaState();
}

class _CanvasAreaState extends ConsumerState<_CanvasArea> {
  final _dropTargetKey = GlobalKey();

  /// Key on the inner canvas container (inside FittedBox), used for
  /// coordinate conversion that correctly accounts for FittedBox scaling.
  final _canvasKey = GlobalKey();

  Offset _toCanvasPosition(Offset globalPos) {
    final box = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return globalPos;
    return box.globalToLocal(globalPos);
  }

  Size _declaredSize(Map<String, Binding> properties) {
    double read(String key, double fallback) {
      final p = properties[key]?.mapOrNull(literal: (b) => b.value);
      return (p as num?)?.toDouble() ?? fallback;
    }

    return Size(
      read('width', kDefaultNodeWidth),
      read('height', kDefaultNodeHeight),
    );
  }

  /// Nudges [dropPos] to the nearest nearby spot (in a small expanding
  /// spiral) whose [size] box doesn't overlap any existing node, clamped to
  /// stay on the canvas. Falls back to the original drop position if every
  /// candidate is still occupied (a densely-packed canvas) — overlap here is
  /// a papercut to avoid, not something to block on.
  Offset _avoidOverlap(
    Offset dropPos,
    Size size,
    List<CanvasNode> existingNodes,
    Size canvasSize,
  ) {
    Offset clamp(Offset p) => Offset(
          p.dx.clamp(0.0, math.max(0.0, canvasSize.width - size.width)),
          p.dy.clamp(0.0, math.max(0.0, canvasSize.height - size.height)),
        );

    bool overlapsAny(Offset p) {
      final candidate = Rect.fromLTWH(p.dx, p.dy, size.width, size.height);
      for (final n in existingNodes) {
        final w =
            _declaredSize((n.data as WidgetInstance?)?.properties ?? const {});
        if (transformedBounds(n, w.width, w.height).overlaps(candidate)) {
          return true;
        }
      }
      return false;
    }

    final first = clamp(dropPos);
    if (!overlapsAny(first)) return first;

    // Scaled to the widget's own footprint (plus a gap) — a fixed step
    // shorter than the widget itself could never actually clear an overlap
    // no matter how many rings it searched.
    final step = math.max(size.width, size.height) * 0.55 + 16;
    for (var ring = 1; ring <= 8; ring++) {
      for (final delta in [
        Offset(step * ring, 0),
        Offset(0, step * ring),
        Offset(step * ring, step * ring),
        Offset(-step * ring, 0),
        Offset(0, -step * ring),
        Offset(-step * ring, -step * ring),
        Offset(step * ring, -step * ring),
        Offset(-step * ring, step * ring),
      ]) {
        final candidatePos = clamp(dropPos + delta);
        if (!overlapsAny(candidatePos)) return candidatePos;
      }
    }
    return first;
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);
    final commands = ref.watch(commandStackProvider);
    final canvasSize = ref.watch(canvasSizeProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: TextEditingController(
                    text: canvasSize.width.toString(),
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'W',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: (v) {
                    final w = double.tryParse(v);
                    if (w != null && w > 0) {
                      ref.read(canvasSizeProvider.notifier).state =
                          CanvasSize(width: w, height: canvasSize.height);
                      ref.read(isDirtyProvider.notifier).state = true;
                    }
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text('×', style: TextStyle(fontSize: 14)),
              ),
              SizedBox(
                width: 72,
                child: TextField(
                  controller: TextEditingController(
                    text: canvasSize.height.toString(),
                  ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'H',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontSize: 12),
                  onSubmitted: (v) {
                    final h = double.tryParse(v);
                    if (h != null && h > 0) {
                      ref.read(canvasSizeProvider.notifier).state =
                          CanvasSize(width: canvasSize.width, height: h);
                      ref.read(isDirtyProvider.notifier).state = true;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.screen_rotation, size: 16),
                tooltip: 'Swap orientation',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  ref.read(canvasSizeProvider.notifier).state = CanvasSize(
                    width: canvasSize.height,
                    height: canvasSize.width,
                  );
                  ref.read(isDirtyProvider.notifier).state = true;
                },
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.grid_on,
                  size: 16,
                  color: ref.watch(gridVisibleProvider)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Toggle grid',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  ref.read(gridVisibleProvider.notifier).state =
                      !ref.read(gridVisibleProvider);
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.vertical_align_center,
                  size: 16,
                  color: ref.watch(centerSnapEnabledProvider)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: 'Toggle centre-line snap',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () {
                  ref.read(centerSnapEnabledProvider.notifier).state =
                      !ref.read(centerSnapEnabledProvider);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
            ),
            child: FittedBox(
              child: SizedBox(
                width: canvasSize.width,
                height: canvasSize.height,
                child: DragTarget<Map<String, dynamic>>(
                  key: _dropTargetKey,
                  onAcceptWithDetails: (details) {
                    final kind = details.data['kind'] as String;
                    final tplProps =
                        details.data['props'] as Map<String, Binding>?;
                    final id = ref.read(idGeneratorProvider).next();
                    final properties =
                        tplProps ?? StudioEditor.defaultProperties(kind);
                    final size = _declaredSize(properties);
                    final dropPos = _toCanvasPosition(details.offset);
                    final localPos = _avoidOverlap(
                      dropPos,
                      size,
                      scene.nodes,
                      Size(canvasSize.width, canvasSize.height),
                    );
                    final node = CanvasNode(
                      id: id,
                      transform: NodeTransforms.compose(translation: localPos),
                      data: WidgetInstance(
                        id: id,
                        kind: kind,
                        properties: properties,
                      ),
                    );
                    commands.execute(AddNodeCommand(node));
                    ref.read(isDirtyProvider.notifier).state = true;
                    // A widget has now been dropped at least once — the
                    // first-drop hint has done its job, don't show it again
                    // even if the user later deletes everything.
                    ref.read(settingsServiceProvider).markCanvasHintDismissed();
                  },
                  builder: (context, candidate, rejected) {
                    final borderColor = candidate.isNotEmpty
                        ? Colors.blue
                        : Theme.of(context).colorScheme.outline;
                    return Container(
                      key: _canvasKey,
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor, width: 2),
                        color: candidate.isNotEmpty
                            ? Colors.blue.withValues(alpha: 0.05)
                            : Theme.of(context)
                                .colorScheme
                                .surface
                                .withValues(alpha: 0.98),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          EditorCanvas(
                            scene: scene,
                            selection: selection,
                            commands: commands,
                            canvasSize:
                                Size(canvasSize.width, canvasSize.height),
                            showGrid: ref.watch(gridVisibleProvider),
                            snapConfig: SnapConfig(
                              enableCenterSnap:
                                  ref.watch(centerSnapEnabledProvider),
                            ),
                            onCommandExecuted: (_) =>
                                ref.read(isDirtyProvider.notifier).state = true,
                            isNodeLocked: (node) {
                              final w = node.data as WidgetInstance?;
                              return w?.properties['locked']?.mapOrNull(
                                      literal: (b) => b.value as bool?) ??
                                  false;
                            },
                            nodeBuilder: (node) {
                              final w = node.data as WidgetInstance?;
                              if (w == null) {
                                return const Center(child: Text('No data'));
                              }
                              final store =
                                  ref.read(canvasPreviewTelemetryProvider);
                              return buildWidget(w, _resolve(w, store));
                            },
                            nodeWidth: (node) {
                              final w = node.data as WidgetInstance?;
                              final p = w?.properties['width']
                                  ?.mapOrNull(literal: (b) => b.value);
                              return (p as num?)?.toDouble() ??
                                  kDefaultNodeWidth;
                            },
                            nodeHeight: (node) {
                              final h = node.data as WidgetInstance?;
                              final p = h?.properties['height']
                                  ?.mapOrNull(literal: (b) => b.value);
                              return (p as num?)?.toDouble() ??
                                  kDefaultNodeHeight;
                            },
                          ),
                          if (scene.length == 0 &&
                              !ref
                                  .watch(settingsServiceProvider)
                                  .canvasHintDismissed)
                            const _FirstDropHint(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Map<String, Binding> defaultProperties(String kind) {
    return switch (kind) {
      'gauge' => {
          'value': const Binding.telemetry(key: 'erpm'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 30000),
          'label': const Binding.literal(value: 'RPM'),
        },
      'bar' => {
          'value': const Binding.telemetry(key: 'duty'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 1),
        },
      'text' => {
          'value': const Binding.telemetry(key: 'v_in'),
          'label': const Binding.literal(value: 'Value'),
        },
      'status' => {
          'fault': const Binding.telemetry(key: 'fault'),
        },
      'chart' => {
          'value': const Binding.telemetry(key: 'erpm'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 30000),
          'label': const Binding.literal(value: 'RPM'),
        },
      'minigauge' => {
          'value': const Binding.telemetry(key: 'duty'),
          'min': const Binding.literal(value: 0),
          'max': const Binding.literal(value: 1),
          'label': const Binding.literal(value: 'Duty'),
          'unit': const Binding.literal(value: '%'),
        },
      'battery_range' => {
          'batteryLevel': const Binding.telemetry(key: 'battery_level'),
          'range': const Binding.telemetry(key: 'range_est'),
          'color': const Binding.literal(value: 0xFF66BB6A),
        },
      'tripstats' => {
          'label1': const Binding.literal(value: 'Speed'),
          'value1': const Binding.telemetry(key: 'speed'),
          'label2': const Binding.literal(value: 'Temp'),
          'value2': const Binding.telemetry(key: 'temp.motor'),
        },
      'car_viz' => {
          'laneLeft': const Binding.telemetry(key: 'lane_left'),
          'laneRight': const Binding.telemetry(key: 'lane_right'),
          'carAhead': const Binding.telemetry(key: 'car_ahead'),
        },
      'power_flow' => {
          'power': const Binding.telemetry(key: 'power'),
          'maxPower': const Binding.literal(value: 5000),
          'color': const Binding.literal(value: 0xFF4FC3F7),
        },
      'gear_selector' => {
          'currentGear': const Binding.telemetry(key: 'gear'),
          'gears': const Binding.literal(value: 'P,R,N,D'),
          'activeColor': const Binding.literal(value: 0xFF4FC3F7),
        },
      'image' => {
          'src': const Binding.literal(value: 'assets/images/placeholder.png'),
        },
      'web' => {
          'url': const Binding.literal(value: 'https://example.com'),
          'title': const Binding.literal(value: 'Live page'),
        },
      'paint' => {
          'program': Binding.literal(value: _samplePaintProgram.toJson()),
          'r': const Binding.telemetry(key: 'temp.mosfet'),
        },
      _ => {
          'label': const Binding.literal(value: 'Widget'),
        },
    };
  }

  static Map<String, dynamic> _resolve(WidgetInstance w, TelemetryStore store) {
    final out = <String, dynamic>{};
    for (final entry in w.properties.entries) {
      final v = entry.value.map(
        literal: (b) => b.value,
        telemetry: (b) => store.value(b.key),
        graph: (_) => null,
        formula: (_) => null,
      );
      if (v != null) out[entry.key] = v;
    }
    return out;
  }
}

/// A one-time, dismissible hint pointing a first-time user at the palette —
/// shown only while the canvas is empty and never dismissed before. Ignores
/// pointer events so it never blocks the drag-drop it's explaining.
class _FirstDropHint extends ConsumerWidget {
  const _FirstDropHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  'Drag a widget from the palette to add it here',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
