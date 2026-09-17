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
              ..._PropertiesInspector._buildProperties(node, widget),
            ],
          ],
        ),
      ),
    );
  }

  static List<Widget> _buildProperties(
    CanvasNode node,
    WidgetInstance widget,
  ) {
    final categorized = categorizedProperties(widget.kind);
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
    if (m.key == 'fontSize') return const Binding.literal(value: 20);
    // Canonical 'w700' (not the 'bold' alias) so the fontWeight picker's
    // options — which use the canonical w100..w900 forms — can actually
    // match and highlight the current value.
    if (m.key == 'fontWeight') return const Binding.literal(value: 'w700');
    if (m.key == 'fontFamily') return const Binding.literal(value: '');
    if (m.key == 'sweepAngle') return const Binding.literal(value: 270.0);
    if (m.key == 'startAngle') return const Binding.literal(value: 135.0);
    if (m.key == 'tickCount') return const Binding.literal(value: 10);
    if (m.key == 'arcWidth') return const Binding.literal(value: 10.0);
    if (m.key == 'lineWidth') return const Binding.literal(value: 2.0);
    if (m.key == 'showGrid') return const Binding.literal(value: true);
    if (m.key == 'showLabels') return const Binding.literal(value: true);
    if (m.key == 'smoothCurve') return const Binding.literal(value: true);
    if (m.key == 'fillArea') return const Binding.literal(value: false);
    if (m.key == 'window') return const Binding.literal(value: 120);
    if (m.key == 'js') return const Binding.literal(value: true);
    // Any property with a fixed set of valid values (orientation,
    // needleStyle, mapStyle, ...) defaults to its first declared option —
    // a real, valid value, instead of falling through to the numeric `0`
    // below, which is meaningless for a string-enum property and was
    // exactly the "unrecognizable value with no visible options" bug.
    if (m.options != null && m.options!.isNotEmpty) {
      return Binding.literal(value: m.options!.first.value);
    }
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
        label: name,
        category: PropertyCategory.visuals,
      ),
    );
    return Tooltip(
      message: propertyDescription(meta.key, meta.label),
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
                _BindingIndicator(
                  binding: binding,
                  onLiteral: () =>
                      _commit(ref, const Binding.literal(value: 0)),
                  onTelemetry: () =>
                      _commit(ref, const Binding.telemetry(key: 'erpm')),
                  onFormula: () => _commit(
                      ref, const Binding.formula(expression: 'erpm / 1000')),
                  onGraph: () => _commit(
                      ref, const Binding.graph(graphId: '', output: '')),
                ),
              ],
            ),
            const SizedBox(height: 4),
            binding.map(
              literal: (b) => meta.options != null
                  ? _EnumEditor(
                      value: b.value is String ? b.value as String : '',
                      options: meta.options!,
                      onChanged: (v) => _commit(ref, Binding.literal(value: v)),
                    )
                  : switch (name) {
                      'fontFamily' => _FontFamilyEditor(
                          value: b.value is String ? b.value as String : '',
                          onChanged: (v) =>
                              _commit(ref, Binding.literal(value: v)),
                        ),
                      'fontWeight' => _FontWeightEditor(
                          value: b.value is String ? b.value as String : 'w400',
                          onChanged: (v) =>
                              _commit(ref, Binding.literal(value: v)),
                        ),
                      _ => _LiteralEditor(
                          value: b.value,
                          meta: meta,
                          onChanged: (v) =>
                              _commit(ref, Binding.literal(value: v)),
                        ),
                    },
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

enum _BindingKind { literal, telemetry, formula, graph }

const Map<_BindingKind, IconData> _bindingKindIcons = {
  _BindingKind.literal: Icons.edit_outlined,
  _BindingKind.telemetry: Icons.sensors,
  _BindingKind.formula: Icons.functions,
  _BindingKind.graph: Icons.share,
};

const Map<_BindingKind, String> _bindingKindLabels = {
  _BindingKind.literal: 'Literal value',
  _BindingKind.telemetry: 'Telemetry binding',
  _BindingKind.formula: 'Formula expression',
  _BindingKind.graph: 'Graph binding',
};

/// A single compact indicator for a property's binding type — replaces four
/// always-visible Lit/Tel/F(x)/Graph chips with one icon whose color encodes
/// state (grey = static literal, green = dynamically bound), matching
/// SimHub Dash Studio's binding-indicator pattern. Tapping opens a popup to
/// switch binding type; the actual value editor stays below, unchanged.
class _BindingIndicator extends StatelessWidget {
  final Binding binding;
  final VoidCallback onLiteral;
  final VoidCallback onTelemetry;
  final VoidCallback onFormula;
  final VoidCallback onGraph;
  const _BindingIndicator({
    required this.binding,
    required this.onLiteral,
    required this.onTelemetry,
    required this.onFormula,
    required this.onGraph,
  });

  _BindingKind get _kind => binding.map(
        literal: (_) => _BindingKind.literal,
        telemetry: (_) => _BindingKind.telemetry,
        formula: (_) => _BindingKind.formula,
        graph: (_) => _BindingKind.graph,
      );

  void _onSelected(_BindingKind kind) {
    switch (kind) {
      case _BindingKind.literal:
        onLiteral();
      case _BindingKind.telemetry:
        onTelemetry();
      case _BindingKind.formula:
        onFormula();
      case _BindingKind.graph:
        onGraph();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final bound = kind != _BindingKind.literal;
    final color = bound ? Colors.green.shade600 : Colors.grey.shade500;
    return Tooltip(
      message: '${_bindingKindLabels[kind]} — tap to change binding type',
      child: PopupMenuButton<_BindingKind>(
        tooltip: '',
        padding: EdgeInsets.zero,
        icon: Icon(_bindingKindIcons[kind], size: 18, color: color),
        onSelected: _onSelected,
        itemBuilder: (context) => _BindingKind.values
            .map(
              (k) => PopupMenuItem(
                value: k,
                child: Row(
                  children: [
                    Icon(
                      _bindingKindIcons[k],
                      size: 16,
                      color: k == kind
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _bindingKindLabels[k]!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (k == kind) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check, size: 16),
                    ],
                  ],
                ),
              ),
            )
            .toList(),
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
  late final FocusNode _focusNode;
  bool _isColor = false;

  @override
  void initState() {
    super.initState();
    _isColor = widget.value is int && (widget.value as int) > 0xFF000000;
    _controller = TextEditingController(text: _format(widget.value));
    // Commit on blur/submit only, not per keystroke: committing on every
    // keystroke round-trips through didUpdateWidget, which can overwrite
    // _controller.text mid-typing and silently drop a just-typed space.
    _focusNode = FocusNode()
      ..addListener(() {
        if (!_focusNode.hasFocus) _apply(_controller.text);
      });
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
    _focusNode.dispose();
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
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true),
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
            focusNode: _focusNode,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(isDense: true),
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

/// A searchable dropdown for the `fontFamily` property — previously a raw
/// text field (and, worse, defaulted to the literal integer `0` before a
/// value was ever set — see `_defaultBinding`), which is exactly why "you
/// can't select fonts, they're just an integer" was a fair complaint.
/// Built on [Autocomplete] since that's the stock Flutter widget for
/// "type to filter, pick from a dropdown," matching what most other
/// programs' font pickers do rather than inventing a bespoke one.
class _FontFamilyEditor extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _FontFamilyEditor({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final choices = ref.watch(fontChoicesProvider);
    final current = choices.firstWhere(
      (f) => f.fontFamily == value,
      orElse: () => FontChoice(label: value, fontFamily: value),
    );
    return Autocomplete<FontChoice>(
      // Rekeyed on the incoming value so an external change (undo/redo,
      // switching selection) resets Autocomplete's own internal text
      // controller — it only reads `initialValue` once per Element, same
      // reason _LiteralEditor manually resyncs its controller in
      // didUpdateWidget.
      key: ValueKey(value),
      initialValue: TextEditingValue(text: current.label),
      displayStringForOption: (f) => f.label,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return choices;
        return choices.where((f) => f.label.toLowerCase().contains(q));
      },
      onSelected: (f) => onChanged(f.fontFamily),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // Autocomplete pre-fills the field with the current selection's
        // label, and filters options by whatever text is currently in the
        // field — so opening the field without clearing it first only ever
        // matches itself (e.g. "Default" matches only the "Default" entry),
        // making every other choice look like it doesn't exist. Clearing on
        // focus shows the full list immediately, matching a standard
        // combobox; restoring the label on blur if nothing was picked keeps
        // the field showing the actual current value at rest.
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              controller.clear();
            } else if (controller.text != current.label) {
              controller.text = current.label;
            }
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              suffixIcon: Icon(Icons.arrow_drop_down, size: 18),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => _OptionsList(
        options: options,
        onSelected: onSelected,
        labelOf: (f) => f.label,
        styleOf: (f) => TextStyle(
          fontFamily: f.fontFamily.isEmpty ? null : f.fontFamily,
          fontSize: 13,
        ),
      ),
    );
  }
}

/// A searchable dropdown for the `fontWeight` property — same reasoning and
/// pattern as [_FontFamilyEditor]. Values are the canonical `w100`..`w900`
/// strings `_parseFontWeight` (in `cosmetic_helpers.dart`) accepts.
class _FontWeightEditor extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _FontWeightEditor({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final current = kFontWeightChoices.firstWhere(
      (f) => f.value == value,
      orElse: () => FontWeightChoice(label: value, value: value),
    );
    return Autocomplete<FontWeightChoice>(
      key: ValueKey(value),
      initialValue: TextEditingValue(text: current.label),
      displayStringForOption: (f) => f.label,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return kFontWeightChoices;
        return kFontWeightChoices
            .where((f) => f.label.toLowerCase().contains(q));
      },
      onSelected: (f) => onChanged(f.value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // See _FontFamilyEditor's fieldViewBuilder — same fix, same reason.
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              controller.clear();
            } else if (controller.text != current.label) {
              controller.text = current.label;
            }
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              suffixIcon: Icon(Icons.arrow_drop_down, size: 18),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) => _OptionsList(
        options: options,
        onSelected: onSelected,
        labelOf: (f) => f.label,
      ),
    );
  }
}

/// A searchable dropdown for any property with a fixed set of valid string
/// values declared via `PropertyMeta.options` (a "style"/mode/unit toggle,
/// not free text) — same pattern and same focus-clear-on-open fix as
/// [_FontFamilyEditor]/[_FontWeightEditor], generalised so a new enum-like
/// property doesn't need its own bespoke editor class.
class _EnumEditor extends StatelessWidget {
  final String value;
  final List<EnumOption> options;
  final ValueChanged<String> onChanged;
  const _EnumEditor({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (o) => o.value == value,
      orElse: () => EnumOption(label: value, value: value),
    );
    return Autocomplete<EnumOption>(
      key: ValueKey(value),
      initialValue: TextEditingValue(text: current.label),
      displayStringForOption: (o) => o.label,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return options;
        return options.where((o) => o.label.toLowerCase().contains(q));
      },
      onSelected: (o) => onChanged(o.value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        // See _FontFamilyEditor's fieldViewBuilder — same fix, same reason:
        // Autocomplete filters options by the field's current text, so
        // opening it pre-filled with the current label only ever matched
        // itself.
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              controller.clear();
            } else if (controller.text != current.label) {
              controller.text = current.label;
            }
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              suffixIcon: Icon(Icons.arrow_drop_down, size: 18),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, opts) => _OptionsList(
        options: opts,
        onSelected: onSelected,
        labelOf: (o) => o.label,
      ),
    );
  }
}

/// Shared dropdown-list popup for [_FontFamilyEditor]/[_FontWeightEditor]'s
/// `optionsViewBuilder` — a plain [Material]-backed list under the field,
/// styled consistently between the two pickers.
class _OptionsList<T extends Object> extends StatelessWidget {
  final Iterable<T> options;
  final ValueChanged<T> onSelected;
  final String Function(T) labelOf;
  final TextStyle Function(T)? styleOf;
  const _OptionsList({
    required this.options,
    required this.onSelected,
    required this.labelOf,
    this.styleOf,
  });

  @override
  Widget build(BuildContext context) {
    final list = options.toList();
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
          child: list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No match', style: TextStyle(fontSize: 12)),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final option = list[i];
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      title: Text(
                        labelOf(option),
                        style: styleOf?.call(option) ??
                            const TextStyle(fontSize: 13),
                      ),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Picker for a telemetry-bound property's key: a searchable list of every
/// known VESC field (shown by human-readable name, e.g. "Motor Speed
/// (ERPM)" rather than the raw `erpm` a beginner has no reason to know) —
/// same Autocomplete + clear-on-focus pattern as [_EnumEditor]/
/// [_FontFamilyEditor]. Typing something that isn't in the list and
/// pressing Enter commits it directly as a custom key (a VESC LispBM
/// variable, or anything else not in [TelemetryKey.all]) — this replaces
/// the previous separate "Manual" mode toggle with one unified field that
/// does both jobs.
class _TelemetryEditor extends StatelessWidget {
  final String currentKey;
  final ValueChanged<String> onChanged;
  const _TelemetryEditor({required this.currentKey, required this.onChanged});

  static final List<EnumOption> _options = [
    for (final key in TelemetryKey.all)
      EnumOption(label: '${telemetryKeyLabel(key)} ($key)', value: key),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _options.firstWhere(
      (o) => o.value == currentKey,
      orElse: () => EnumOption(
          label: '${telemetryKeyLabel(currentKey)} ($currentKey)',
          value: currentKey),
    );
    return Autocomplete<EnumOption>(
      key: ValueKey(currentKey),
      initialValue: TextEditingValue(text: current.label),
      displayStringForOption: (o) => o.label,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return _options;
        return _options.where((o) => o.label.toLowerCase().contains(q));
      },
      onSelected: (o) => onChanged(o.value),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) {
              controller.clear();
            } else if (controller.text != current.label) {
              controller.text = current.label;
            }
          },
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'Pick, or type a custom variable',
              suffixIcon: Icon(Icons.arrow_drop_down, size: 18),
            ),
            onFieldSubmitted: (text) {
              final trimmed = text.trim();
              if (trimmed.isEmpty) return;
              // Submitting exactly what a list entry displays picks that
              // entry; anything else is taken as a literal custom key.
              final match = _options.firstWhere(
                (o) => o.label.toLowerCase() == trimmed.toLowerCase(),
                orElse: () => EnumOption(label: trimmed, value: trimmed),
              );
              onChanged(match.value);
            },
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, opts) => _OptionsList(
        options: opts,
        onSelected: onSelected,
        labelOf: (o) => o.label,
      ),
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
        Tooltip(
          message: 'A math expression. Telemetry keys (e.g. erpm, '
              'temp.mosfet) and functions are available:\n'
              'min(a, b, ...), max(a, b, ...), clamp(v, lo, hi),\n'
              'abs(v), round(v), floor(v), ceil(v), sqrt(v)',
          child: Icon(Icons.functions, size: 16, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: TextEditingController(text: expression),
            decoration: const InputDecoration(
              hintText: 'clamp(erpm / 1000, 0, 30)',
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
