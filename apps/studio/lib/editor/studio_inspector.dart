part of 'studio_editor.dart';

/// The properties inspector for the current selection.
class _PropertiesInspector extends ConsumerWidget {
  const _PropertiesInspector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.read(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);

    if (selection.isEmpty) {
      // Rather than waste the whole panel on a placeholder message, show
      // canvas-level properties — the things that matter when nothing is
      // selected (background/accent colour). Named dashboard properties
      // (size, name) are already editable elsewhere (canvas toolbar, save
      // dialog) so aren't duplicated here.
      final canvasSize = ref.watch(canvasSizeProvider);
      return Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Canvas', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              '${canvasSize.width.toInt()} × ${canvasSize.height.toInt()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const Divider(height: 24),
            _CanvasColorRow(
              label: 'Background',
              value: ref.watch(backgroundProvider),
              onChanged: (c) {
                ref.read(backgroundProvider.notifier).state = c;
                ref.read(isDirtyProvider.notifier).state = true;
              },
            ),
            const SizedBox(height: 12),
            _CanvasColorRow(
              label: 'Accent',
              value: ref.watch(accentProvider),
              onChanged: (c) {
                ref.read(accentProvider.notifier).state = c;
                ref.read(isDirtyProvider.notifier).state = true;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Select a widget to edit its properties',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final node = scene[selection.single ?? selection.ids.first];
    if (node == null) return const SizedBox.shrink();
    final widget = node.data as WidgetInstance?;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Properties',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete widget',
                  onPressed: () {
                    ref
                        .read(commandStackProvider)
                        .execute(RemoveNodesCommand([node]));
                    ref.read(selectionModelProvider).clear();
                    ref.read(isDirtyProvider.notifier).state = true;
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget != null) ...[
              _Field(label: 'ID', value: widget.id),
              _Field(label: 'Kind', value: widget.kind),
              const SizedBox(height: 4),
              _PositionFields(node: node),
              const Divider(),
              ..._PropertiesInspector._buildProperties(
                node,
                widget,
                level: ref.watch(capabilityLevelProvider),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildProperties(
    CanvasNode node,
    WidgetInstance widget, {
    CapabilityLevel level = CapabilityLevel.expert,
  }) {
    final categorized = categorizedProperties(widget.kind, level: level);
    final entries = Map<String, Binding>.from(widget.properties);
    final result = <Widget>[];

    if (widget.kind == 'paint') {
      result.add(_PaintProgramEditor(node: node, widget: widget));
    }

    // Only the first non-empty category starts open — landing on a newly
    // selected widget with every section already expanded is overwhelming
    // (SimHub's property grid keeps almost everything collapsed/flat by
    // default too). The rest are one tap away.
    var firstExpanded = false;

    for (final category in PropertyCategory.values) {
      final categoryMetas = categorized[category] ?? [];
      final filteredMetas = widget.kind == 'paint'
          ? categoryMetas.where((m) => m.key != 'program').toList()
          : categoryMetas;

      if (filteredMetas.isNotEmpty) {
        final expandThisOne = !firstExpanded;
        firstExpanded = true;
        result.add(
          ExpansionTile(
            title: Text(
              category.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            initiallyExpanded: expandThisOne,
            dense: true,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 4),
            children: [
              for (final m in filteredMetas)
                _BindingField(
                  node: node,
                  widget: widget,
                  name: m.key,
                  binding: entries[m.key] ?? _defaultBinding(m),
                ),
            ],
          ),
        );
      }
    }
    return result;
  }

  static Binding _defaultBinding(PropertyMeta m) {
    // Provide sensible defaults so the property shows up editable.
    if (m.key == 'visible') return const Binding.literal(value: true);
    if (m.key == 'opacity') return const Binding.literal(value: 1.0);
    if (m.key == 'padding') return const Binding.literal(value: 12);
    if (m.key == 'width') return const Binding.literal(value: 300);
    if (m.key == 'height') return const Binding.literal(value: 220);
    if (m.key == 'orientation')
      return const Binding.literal(value: 'horizontal');
    if (m.key == 'sourceUnit') return const Binding.literal(value: 'kmh');
    if (m.key == 'displayUnit') return const Binding.literal(value: '');
    if (m.key == 'needleStyle') return const Binding.literal(value: 'arc');
    if (m.key == 'fontSize') return const Binding.literal(value: 20);
    if (m.key == 'fontWeight') return const Binding.literal(value: 'bold');
    if (m.key == 'sweepAngle') return const Binding.literal(value: 270.0);
    if (m.key == 'startAngle') return const Binding.literal(value: 135.0);
    if (m.key == 'tickCount') return const Binding.literal(value: 10);
    if (m.key == 'arcWidth') return const Binding.literal(value: 10.0);
    if (m.key == 'lineWidth') return const Binding.literal(value: 2.0);
    if (m.key == 'showGrid') return const Binding.literal(value: true);
    if (m.key == 'smoothCurve') return const Binding.literal(value: true);
    if (m.key == 'fillArea') return const Binding.literal(value: false);
    if (m.key == 'window') return const Binding.literal(value: 120);
    if (m.key == 'js') return const Binding.literal(value: true);
    final isColour = m.key == 'color' ||
        m.key == 'accent' ||
        m.key == 'backgroundColor' ||
        m.key == 'borderColor' ||
        m.key == 'shadowColor' ||
        m.key == 'fillColor' ||
        m.key == 'gridColor' ||
        m.key == 'tint';
    if (isColour) return const Binding.literal(value: 0xFFFFFFFF);
    final isNum = m.key == 'min' ||
        m.key == 'max' ||
        m.key == 'borderRadius' ||
        m.key == 'borderWidth' ||
        m.key == 'shadowBlur' ||
        m.key == 'shadowOffsetY' ||
        m.key == 'letterSpacing' ||
        m.key == 'barRadius';
    if (isNum) return const Binding.literal(value: 0);
    return const Binding.literal(value: 0);
  }
}

class _PositionFields extends ConsumerWidget {
  final CanvasNode node;
  const _PositionFields({required this.node});

  /// Current rotation in degrees, decoded from the transform's 2x2 linear
  /// part. NodeTransforms.compose builds translate*rotationZ(θ)*scale, so
  /// for entries a=cos·s, b=sin·s (column 0), θ = atan2(b, a) regardless of
  /// the (uniform, positive) scale factor.
  double _rotationDegrees(Matrix4 t) {
    final a = t.entry(0, 0);
    final b = t.entry(1, 0);
    return math.atan2(b, a) * 180 / math.pi;
  }

  double _uniformScale(Matrix4 t) {
    final a = t.entry(0, 0);
    final b = t.entry(1, 0);
    final s = math.sqrt(a * a + b * b);
    return s == 0 ? 1.0 : s;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final x = node.transform.entry(0, 3).toInt();
    final y = node.transform.entry(1, 3).toInt();
    final rotation = _rotationDegrees(node.transform).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                'Position',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            SizedBox(
              width: 62,
              child: TextFormField(
                initialValue: x.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'X',
                  labelStyle: const TextStyle(fontSize: 10),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) => _commitPosition(ref, 'x', v),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 62,
              child: TextFormField(
                initialValue: y.toString(),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: 'Y',
                  labelStyle: const TextStyle(fontSize: 10),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) => _commitPosition(ref, 'y', v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                'Rotation',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
            SizedBox(
              width: 62,
              child: TextFormField(
                key: ValueKey('rotation_${node.id}_$rotation'),
                initialValue: rotation.toString(),
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  labelText: '°',
                  labelStyle: const TextStyle(fontSize: 10),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  border: const OutlineInputBorder(),
                ),
                onFieldSubmitted: (v) => _commitRotation(ref, v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _commitRotation(WidgetRef ref, String raw) {
    final degrees = double.tryParse(raw);
    if (degrees == null) return;
    final oldT = node.transform.clone();
    final translation =
        Offset(node.transform.entry(0, 3), node.transform.entry(1, 3));
    final scale = _uniformScale(node.transform);
    final newT = NodeTransforms.compose(
      translation: translation,
      scale: scale,
      rotation: degrees * math.pi / 180,
    );
    ref.read(commandStackProvider).execute(
          TransformNodesCommand({node.id: (oldT, newT)}),
        );
    ref.read(isDirtyProvider.notifier).state = true;
  }

  void _commitPosition(WidgetRef ref, String axis, String raw) {
    final value = double.tryParse(raw);
    if (value == null) return;
    final oldT = node.transform.clone();
    final newT = Matrix4.copy(node.transform);
    if (axis == 'x') {
      newT.setEntry(0, 3, value);
    } else {
      newT.setEntry(1, 3, value);
    }
    ref.read(commandStackProvider).execute(
          TransformNodesCommand({node.id: (oldT, newT)}),
        );
    ref.read(isDirtyProvider.notifier).state = true;
  }
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  const _Field({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _BindingField extends ConsumerWidget {
  final CanvasNode node;
  final WidgetInstance widget;
  final String name;
  final Binding binding;
  const _BindingField({
    required this.node,
    required this.widget,
    required this.name,
    required this.binding,
  });

  void _commit(WidgetRef ref, Binding newBinding) {
    final newProps = Map<String, Binding>.from(widget.properties);
    newProps[name] = newBinding;
    final newWidget = widget.copyWith(properties: newProps);
    ref.read(commandStackProvider).execute(
          UpdateNodeDataCommand(
            id: node.id,
            oldData: widget,
            newData: newWidget,
          ),
        );
    ref.read(isDirtyProvider.notifier).state = true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = allProperties(widget.kind).firstWhere(
      (m) => m.key == name,
      orElse: () => PropertyMeta(
        key: name,
        minLevel: CapabilityLevel.basic,
        label: name,
        category: PropertyCategory.visuals,
      ),
    );
    return Tooltip(
      message: 'Property "${meta.label}" (${meta.key})',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meta.label,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                _BindingTypeChip(
                  label: 'Lit',
                  tooltipMessage: 'Literal value',
                  active: binding is LiteralBinding,
                  onTap: () => _commit(ref, const Binding.literal(value: 0)),
                ),
                _BindingTypeChip(
                  label: 'Tel',
                  tooltipMessage: 'Telemetry binding',
                  active: binding is TelemetryBinding,
                  onTap: () =>
                      _commit(ref, const Binding.telemetry(key: 'erpm')),
                ),
                _BindingTypeChip(
                  label: 'F(x)',
                  tooltipMessage: 'Formula expression',
                  active: binding is FormulaBinding,
                  onTap: () => _commit(
                      ref, const Binding.formula(expression: 'erpm / 1000')),
                ),
                _BindingTypeChip(
                  label: 'Graph',
                  tooltipMessage: 'Graph binding',
                  active: binding is GraphBinding,
                  onTap: () =>
                      _commit(ref, Binding.graph(graphId: '', output: '')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            binding.map(
              literal: (b) => _LiteralEditor(
                value: b.value,
                meta: meta,
                onChanged: (v) => _commit(ref, Binding.literal(value: v)),
              ),
              telemetry: (b) => _TelemetryEditor(
                currentKey: b.key,
                onChanged: (k) => _commit(ref, Binding.telemetry(key: k)),
              ),
              graph: (b) => _GraphEditor(
                graphId: b.graphId,
                output: b.output,
                onChanged: (gid, out) =>
                    _commit(ref, Binding.graph(graphId: gid, output: out)),
              ),
              formula: (b) => _FormulaEditor(
                expression: b.expression,
                onChanged: (expr) =>
                    _commit(ref, Binding.formula(expression: expr)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BindingTypeChip extends StatelessWidget {
  final String label;
  final String tooltipMessage;
  final bool active;
  final VoidCallback onTap;
  const _BindingTypeChip({
    required this.label,
    required this.tooltipMessage,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltipMessage,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: active
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}

class _LiteralEditor extends StatefulWidget {
  final Object value;
  final PropertyMeta? meta;
  final ValueChanged<Object> onChanged;
  const _LiteralEditor({
    required this.value,
    this.meta,
    required this.onChanged,
  });

  @override
  State<_LiteralEditor> createState() => _LiteralEditorState();
}

class _LiteralEditorState extends State<_LiteralEditor> {
  late final TextEditingController _controller;
  bool _isColor = false;

  @override
  void initState() {
    super.initState();
    _isColor = widget.value is int && (widget.value as int) > 0xFF000000;
    _controller = TextEditingController(text: _format(widget.value));
  }

  String _format(Object v) {
    if (v is num) return v.toString();
    return v.toString();
  }

  static int? parseHexColor(String input) {
    final clean = input.replaceAll('#', '').trim();
    if (clean.length == 6) {
      return int.tryParse('FF$clean', radix: 16);
    } else if (clean.length == 8) {
      return int.tryParse(clean, radix: 16);
    }
    return null;
  }

  @override
  void didUpdateWidget(covariant _LiteralEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _format(widget.value);
      _isColor = widget.value is int && (widget.value as int) > 0xFF000000;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isColor) {
      final colorVal = (widget.value as num).toInt();
      return Row(
        children: [
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<int>(
                context: context,
                builder: (context) => SimpleColorPicker(current: colorVal),
              );
              if (picked != null) widget.onChanged(picked);
            },
            child: Container(
              width: 40,
              height: 28,
              decoration: BoxDecoration(
                color: Color(colorVal),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _isColor = false),
            child: const Text('Hex', style: TextStyle(fontSize: 11)),
          ),
        ],
      );
    }

    final hasSlider = widget.meta?.min != null &&
        widget.meta?.max != null &&
        widget.value is num;

    if (hasSlider) {
      final minVal = widget.meta!.min!;
      final maxVal = widget.meta!.max!;
      final double current =
          (widget.value as num).toDouble().clamp(minVal, maxVal);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: current,
                  min: minVal,
                  max: maxVal,
                  divisions: widget.meta!.step != null && widget.meta!.step! > 0
                      ? ((maxVal - minVal) / widget.meta!.step!).round()
                      : null,
                  label: current.toStringAsFixed(1),
                  onChanged: (val) {
                    final stepVal =
                        widget.meta!.step != null && widget.meta!.step! > 0
                            ? (val / widget.meta!.step!).round() *
                                widget.meta!.step!
                            : val;
                    widget.onChanged(
                        widget.value is int ? stepVal.round() : stepVal);
                  },
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  current.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 11),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          TextFormField(
            controller: _controller,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true),
            onChanged: (s) => _apply(s),
            onFieldSubmitted: (s) => _apply(s),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true),
            onChanged: (s) => _apply(s),
            onFieldSubmitted: (s) => _apply(s),
          ),
        ),
        if (widget.value is int && (widget.value as int) > 0xFF000000)
          TextButton(
            onPressed: () => setState(() => _isColor = true),
            child: const Text('Color', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  void _apply(String s) {
    final trimmed = s.trim();
    final hexVal = parseHexColor(trimmed);
    if (hexVal != null) {
      widget.onChanged(hexVal);
      return;
    }
    final n = num.tryParse(trimmed);
    widget.onChanged(n ?? trimmed);
  }
}

class _TelemetryEditor extends StatefulWidget {
  final String currentKey;
  final ValueChanged<String> onChanged;
  const _TelemetryEditor({required this.currentKey, required this.onChanged});

  @override
  State<_TelemetryEditor> createState() => _TelemetryEditorState();
}

class _TelemetryEditorState extends State<_TelemetryEditor> {
  bool _manual = false;
  String _filterQuery = '';
  late final TextEditingController _filterController;

  @override
  void initState() {
    super.initState();
    _filterController = TextEditingController();
  }

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_manual) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: widget.currentKey,
              style: const TextStyle(fontSize: 12),
              decoration:
                  const InputDecoration(isDense: true, hintText: 'e.g. fault'),
              onFieldSubmitted: (v) {
                if (v.trim().isNotEmpty) widget.onChanged(v.trim());
                setState(() => _manual = false);
              },
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _manual = false),
            child: const Text('Pick', style: TextStyle(fontSize: 11)),
          ),
        ],
      );
    }

    final matchingKeys = TelemetryKey.all
        .where((k) => k.toLowerCase().contains(_filterQuery.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _filterController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  hintText: 'Filter keys...',
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _filterQuery = v),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _manual = true),
              child: const Text('Manual', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        DropdownButton<String>(
          value: matchingKeys.contains(widget.currentKey)
              ? widget.currentKey
              : null,
          isExpanded: true,
          hint: Text(widget.currentKey, style: const TextStyle(fontSize: 12)),
          items: [
            for (final k in matchingKeys)
              DropdownMenuItem(
                value: k,
                child: Text(k, style: const TextStyle(fontSize: 12)),
              )
          ],
          onChanged: (v) {
            if (v != null) widget.onChanged(v);
          },
        ),
      ],
    );
  }
}

class _FormulaEditor extends StatelessWidget {
  final String expression;
  final ValueChanged<String> onChanged;
  const _FormulaEditor({required this.expression, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.functions, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: expression),
            decoration: const InputDecoration(
              hintText: 'erpm / 1000',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _GraphEditor extends StatelessWidget {
  final String graphId;
  final String output;
  final void Function(String, String) onChanged;
  const _GraphEditor(
      {required this.graphId, required this.output, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: graphId,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
                isDense: true,
                labelText: 'Graph',
                labelStyle: TextStyle(fontSize: 10)),
            onFieldSubmitted: (v) => onChanged(v.trim(), output),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            initialValue: output,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
                isDense: true,
                labelText: 'Output',
                labelStyle: TextStyle(fontSize: 10)),
            onFieldSubmitted: (v) => onChanged(graphId, v.trim()),
          ),
        ),
      ],
    );
  }
}

/// A JSON editor for a `paint` widget's program. Edits are committed through
/// an [UpdateNodeDataCommand] so they participate in undo/redo.
class _PaintProgramEditor extends ConsumerStatefulWidget {
  final CanvasNode node;
  final WidgetInstance widget;
  const _PaintProgramEditor({required this.node, required this.widget});

  @override
  ConsumerState<_PaintProgramEditor> createState() =>
      _PaintProgramEditorState();
}

class _PaintProgramEditorState extends ConsumerState<_PaintProgramEditor> {
  late final TextEditingController _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _encodedProgram());
  }

  @override
  void didUpdateWidget(covariant _PaintProgramEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final encoded = _encodedProgram();
    if (encoded != _controller.text && _error == null) {
      _controller.text = encoded;
    }
  }

  String _encodedProgram() {
    final binding = widget.widget.properties['program'];
    final value = binding?.mapOrNull(literal: (b) => b.value);
    if (value is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(value);
      } catch (_) {
        return value.toString();
      }
    }
    return const JsonEncoder.withIndent('  ')
        .convert(const <String, dynamic>{'ops': <dynamic>[]});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final text = _controller.text;
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _error = 'Program must be a JSON object.');
        return;
      }
      // Validate it round-trips through PaintProgram.
      PaintProgram.fromJson(Map<String, dynamic>.from(decoded));
      final newWidget = widget.widget.copyWith(
        properties: {
          ...widget.widget.properties,
          'program': Binding.literal(value: decoded),
        },
      );
      ref.read(commandStackProvider).execute(
            UpdateNodeDataCommand(
              id: widget.node.id,
              oldData: widget.node.data,
              newData: newWidget,
            ),
          );
      ref.read(isDirtyProvider.notifier).state = true;
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Paint program',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            minLines: 8,
            maxLines: 16,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _error,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton.icon(
                onPressed: _commit,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Apply'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  _controller.text = const JsonEncoder.withIndent('  ')
                      .convert(_samplePaintProgram.toJson());
                  setState(() => _error = null);
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Sample'),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Coords may be numbers or "\$var" refs; every non-program '
              'property is a variable.',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

/// A labeled colour-swatch row for canvas-level properties (background,
/// accent), reusing the same SimpleColorPicker dialog the template-tweak
/// panel uses so the picker UI never drifts between the two.
class _CanvasColorRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _CanvasColorRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDialog<int>(
              context: context,
              builder: (context) => SimpleColorPicker(current: value),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: Color(value),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
      ],
    );
  }
}
