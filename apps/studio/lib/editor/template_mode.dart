/// Template mode (Basic) — pick a starter dashboard, preview it live, and
/// tweak the exposed knobs (colours, limits, labels) without entering the
/// full Canvas editor.
///
/// This is the "Basic" capability tier: transforms are locked, only safe
/// properties are editable, and the user starts from a curated template.
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:templates/templates.dart';
import 'package:vesc_telemetry/vesc_telemetry.dart';
import 'package:widgets_library/widgets_library.dart';

import '../providers/editor_providers.dart';
import '../widgets/simple_color_picker.dart';

/// The currently-selected template (null = none).
final selectedTemplateProvider =
    StateProvider<DashboardTemplate?>((ref) => null);

/// The user's knob edits: `'$widgetId.$property'` → value.
final templateEditsProvider =
    StateProvider<Map<String, Object>>((ref) => const {});

/// A mock telemetry store for the template preview (so the preview is live).
final previewTelemetryProvider = Provider<TelemetryStore>((ref) {
  final store = TelemetryStore();
  // Seed with plausible values so widgets render meaningfully.
  store.ingest({
    TelemetryKey.erpm: 12000,
    TelemetryKey.duty: 0.65,
    TelemetryKey.vIn: 50.2,
    TelemetryKey.tempMosfet: 42.0,
    TelemetryKey.tempMotor: 55.0,
    TelemetryKey.currentMotor: 18.5,
    TelemetryKey.focId: -2.1,
    TelemetryKey.focIq: 17.8,
    TelemetryKey.fault: 0,
    TelemetryKey.tachometer: 403438,
    TelemetryKey.tachometerAbs: 403438,
    TelemetryKey.ampHoursDischarged: 12.5,
    TelemetryKey.wattHoursDischarged: 600,
    TelemetryKey.gpsSpeed: 0.0,
    TelemetryKey.gpsLat: 52.52,
    TelemetryKey.gpsLon: 13.405,
    TelemetryKey.gpsHeading: 45.0,
    TelemetryKey.gpsAltitude: 34.0,
    // Custom keys used by advanced example dashboards.
    'speed': 0.0,
    'battery_pct': 85.0,
    'range': 270.0,
    'power': 0.0,
    'odometer': 403.438,
    'trip_distance': 45.2,
    'trip_time': 78.0,
    'avg_speed': 35.0,
    'energy_used': 12.5,
    'duty_cycle': 0.0,
  });
  ref.onDispose(store.dispose);
  return store;
});

class TemplateMode extends ConsumerWidget {
  const TemplateMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTemplateProvider);

    if (selected == null) {
      return const _TemplateGallery();
    }
    return _TemplateEditor(template: selected);
  }
}

/// The gallery grid of starter templates, grouped by category.
class _TemplateGallery extends ConsumerWidget {
  const _TemplateGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTemplates = [...builtInTemplates, ...advancedDashboardTemplates];
    final categories = <String, List<DashboardTemplate>>{};
    for (final t in allTemplates) {
      categories.putIfAbsent(t.category, () => []).add(t);
    }
    final orderedCategories = categories.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a starter dashboard',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Templates give you a working board in seconds. Tweak colours and '
            'limits, then save — or switch to Canvas mode for full control.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: orderedCategories.length,
              itemBuilder: (context, index) {
                final entry = orderedCategories[index];
                return _CategorySection(
                  category: entry.key,
                  templates: entry.value,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String category;
  final List<DashboardTemplate> templates;
  const _CategorySection({required this.category, required this.templates});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) => SizedBox(
                width: 340,
                child: _TemplateCard(template: templates[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final DashboardTemplate template;
  const _TemplateCard({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(previewTelemetryProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () {
          ref.read(selectedTemplateProvider.notifier).state = template;
          ref.read(templateEditsProvider.notifier).state = const {};
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_iconFor(template.id), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _TemplatePreview(
                  document: template.document,
                  store: store,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  _Chip('${template.document.widgets.length} widgets'),
                  _Chip('${template.knobs.length} tweaks'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String id) => switch (id) {
        'minimal' => Icons.speed,
        'performance' => Icons.bolt,
        'commuter' => Icons.directions_car,
        'offroad' => Icons.terrain,
        'tesla-model3' => Icons.electric_car,
        'porsche-taycan' => Icons.sports_motorsports,
        'bmw-classic' => Icons.precision_manufacturing,
        'audi-virtual-cockpit' => Icons.flight,
        'vesc-mobile' => Icons.sensors,
        'android-auto' => Icons.android,
        'carplay' => Icons.phone_iphone,
        'ford-digital' => Icons.local_shipping,
        'vw-digital' => Icons.airport_shuttle,
        _ => Icons.dashboard,
      };
}

class _TemplatePreview extends StatelessWidget {
  final DashboardDocument document;
  final TelemetryStore store;
  const _TemplatePreview({required this.document, required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(document.background),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: FittedBox(
          child: SizedBox(
            width: document.canvas.width,
            height: document.canvas.height,
            child: DashboardThemeProvider(
              theme: DashboardTheme.fromDocument(
                backgroundArgb: document.background,
                accentArgb: document.accent,
              ),
              // Same reasoning as the Canvas editor: the dashboard font
              // applies to the previewed content so this thumbnail actually
              // looks like the real dashboard, without touching Studio's
              // own chrome font.
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontFamily: kDashboardFontFamily),
                child: Stack(
                  children: [
                    // Uses the widget's own declared width/height, same as the
                    // real Canvas editor (see studio_canvas_area.dart's
                    // nodeWidth/nodeHeight) — a hardcoded 300x220 box here
                    // clipped some widgets (e.g. the Porsche trip-stats pod,
                    // designed for 480x480) badly enough to overflow.
                    for (final w in document.widgets)
                      Positioned(
                        left: w.transform[4],
                        top: w.transform[5],
                        width: (w.properties['width']?.mapOrNull(
                                    literal: (b) => b.value) as num?)
                                ?.toDouble() ??
                            300,
                        height: (w.properties['height']?.mapOrNull(
                                    literal: (b) => b.value) as num?)
                                ?.toDouble() ??
                            220,
                        child: buildWidget(w, _resolve(w)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _resolve(WidgetInstance w) {
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

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

/// The template editor: live preview on the left, tweak knobs on the right.
class _TemplateEditor extends ConsumerStatefulWidget {
  final DashboardTemplate template;
  const _TemplateEditor({required this.template});

  @override
  ConsumerState<_TemplateEditor> createState() => _TemplateEditorState();
}

class _TemplateEditorState extends ConsumerState<_TemplateEditor> {
  @override
  Widget build(BuildContext context) {
    final edits = ref.watch(templateEditsProvider);
    final doc = widget.template.applyEdits(edits);
    final store = ref.watch(previewTelemetryProvider);

    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => ref
                          .read(selectedTemplateProvider.notifier)
                          .state = null,
                      tooltip: 'Back to gallery',
                    ),
                    Text(widget.template.name,
                        style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Save & edit in Canvas'),
                      onPressed: () =>
                          _saveAndSwitchToCanvas(context, ref, doc),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _LivePreview(document: doc, store: store)),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 300,
          child: _TweakPanel(template: widget.template),
        ),
      ],
    );
  }

  Future<void> _saveAndSwitchToCanvas(
    BuildContext context,
    WidgetRef ref,
    DashboardDocument doc,
  ) async {
    final db = ref.read(dashboardDatabaseProvider);
    final scene = ref.read(sceneModelProvider);
    final name = widget.template.name;

    final id = await db.saveDashboard(name, doc);
    applyDocumentToEditor(ref, scene: scene, doc: doc, id: id, name: name);
    ref.read(editorModeProvider.notifier).state = EditorMode.canvas;
    ref.read(selectedTemplateProvider.notifier).state = null;
    ref.invalidate(recentDashboardsProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$name" — switched to Canvas mode')),
      );
    }
  }
}

/// Renders the document against mock telemetry (a mini version of the
/// dashboard viewer's render path).
class _LivePreview extends StatelessWidget {
  final DashboardDocument document;
  final TelemetryStore store;

  const _LivePreview({required this.document, required this.store});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        child: SizedBox(
          width: document.canvas.width,
          height: document.canvas.height,
          child: DashboardThemeProvider(
            theme: DashboardTheme.fromDocument(
              backgroundArgb: document.background,
              accentArgb: document.accent,
            ),
            child: ColoredBox(
              color: Color(document.background),
              child: Stack(
                children: [
                  for (final w in document.widgets)
                    Positioned(
                      left: w.transform[4],
                      top: w.transform[5],
                      width: 300,
                      height: 220,
                      child: RepaintBoundary(
                        child: buildWidget(w, _resolve(w, store)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _resolve(WidgetInstance w, TelemetryStore store) {
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

/// The knob-tweaking panel on the right.
class _TweakPanel extends ConsumerWidget {
  final DashboardTemplate template;
  const _TweakPanel({required this.template});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final edits = ref.watch(templateEditsProvider);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey.shade300)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tweak', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Adjust the safe properties. Layout and bindings are locked in '
            'Basic mode — switch to Canvas for those.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                for (final knob in template.knobs)
                  _KnobEditor(
                    knob: knob,
                    currentValue: _currentValue(knob, edits, template),
                    onChanged: (value) {
                      final next = Map<String, Object>.from(edits);
                      next['${knob.widgetId}.${knob.property}'] = value;
                      ref.read(templateEditsProvider.notifier).state = next;
                    },
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to defaults'),
                  onPressed: () =>
                      ref.read(templateEditsProvider.notifier).state = const {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Object _currentValue(
    TemplateKnob knob,
    Map<String, Object> edits,
    DashboardTemplate template,
  ) {
    final key = '${knob.widgetId}.${knob.property}';
    if (edits.containsKey(key)) return edits[key]!;
    final w =
        template.document.widgets.firstWhere((w) => w.id == knob.widgetId);
    final binding = w.properties[knob.property];
    if (binding is LiteralBinding) return binding.value;
    return switch (knob.kind) {
      KnobKind.number => 0,
      KnobKind.color => 0xFFFFFFFF,
      KnobKind.text => '',
    };
  }
}

class _KnobEditor extends StatelessWidget {
  final TemplateKnob knob;
  final Object currentValue;
  final ValueChanged<Object> onChanged;

  const _KnobEditor({
    required this.knob,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: switch (knob.kind) {
        KnobKind.number => _NumberKnob(
            label: knob.label,
            value: (currentValue as num).toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        KnobKind.color => _ColorKnob(
            label: knob.label,
            value: (currentValue as num).toInt(),
            onChanged: onChanged,
          ),
        KnobKind.text => _TextKnob(
            label: knob.label,
            value: currentValue.toString(),
            onChanged: onChanged,
          ),
      },
    );
  }
}

class _NumberKnob extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _NumberKnob({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 90,
          child: TextFormField(
            initialValue: value.toStringAsFixed(0),
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(isDense: true),
            onChanged: (s) {
              final n = num.tryParse(s);
              if (n != null) onChanged(n.toDouble());
            },
          ),
        ),
      ],
    );
  }
}

class _ColorKnob extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _ColorKnob({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
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

class _TextKnob extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _TextKnob({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        SizedBox(
          width: 120,
          child: TextFormField(
            initialValue: value,
            decoration: const InputDecoration(isDense: true),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
