/// A reorderable layer panel showing all widgets ordered by z-height,
/// with visibility toggles and drag-to-reorder z-ordering.
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/editor_providers.dart';

class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});

  static const _kindIcons = <String, IconData>{
    'gauge': Icons.speed,
    'bar': Icons.bar_chart,
    'text': Icons.text_fields,
    'chart': Icons.show_chart,
    'status': Icons.info_outline,
    'image': Icons.image,
    'web': Icons.public,
    'paint': Icons.brush,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);
    final nodes = scene.nodes.toList()
      ..sort((a, b) => b.z.compareTo(a.z));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers, size: 16),
              const SizedBox(width: 8),
              Text('Layers', style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: nodes.length,
            onReorderItem: (oldIndex, newIndex) {
              final reordered = nodes.toList();
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              for (var i = 0; i < reordered.length; i++) {
                final node = reordered[i];
                final z = reordered.length - i;
                if (node.z != z) {
                  scene.upsert(node.copyWith(z: z));
                }
              }
            },
            itemBuilder: (context, index) {
              final node = nodes[index];
              final w = node.data as WidgetInstance?;
              final kind = w?.kind ?? '?';
              final isSelected = selection.ids.contains(node.id);
              final isVisible = _isVisible(w);

              return Container(
                key: ValueKey(node.id),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                      : null,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.3)),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    _kindIcons[kind] ?? Icons.widgets,
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    kind.capitalize(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isVisible ? null : Colors.grey,
                    ),
                  ),
                  subtitle: Text(
                    '#${node.z} · ${node.id.substring(0, 8)}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                      size: 16,
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _toggleVisible(ref, node, w, !isVisible);
                    },
                  ),
                  onTap: () {
                    selection.setAll([node.id]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  bool _isVisible(WidgetInstance? w) {
    if (w == null) return true;
    return w.properties['visible']
            ?.mapOrNull(literal: (b) => b.value as bool?) ??
        true;
  }

  void _toggleVisible(
      WidgetRef ref, CanvasNode node, WidgetInstance? w, bool value) {
    final scene = ref.read(sceneModelProvider);
    final props = Map<String, Binding>.from(w?.properties ?? {});
    props['visible'] = Binding.literal(value: value);
    final kind = w?.kind ?? 'text';
    final updated = (w ?? WidgetInstance(id: node.id, kind: kind))
        .copyWith(properties: props);
    scene.upsert(node.copyWith(data: updated));
    ref.read(isDirtyProvider.notifier).state = true;
  }
}

extension on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
