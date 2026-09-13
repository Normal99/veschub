/// A reorderable layer panel showing all widgets ordered by z-height,
/// with visibility toggles and drag-to-reorder z-ordering.
library;

import 'package:dashboard_model/dashboard_model.dart';
import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:widgets_library/widgets_library.dart' show kindIcon;

import '../document_bridge.dart';
import '../providers/editor_providers.dart';

double _nodeWidth(CanvasNode node) {
  final w = node.data as WidgetInstance?;
  final p = w?.properties['width']?.mapOrNull(literal: (b) => b.value);
  return (p as num?)?.toDouble() ?? kDefaultNodeWidth;
}

double _nodeHeight(CanvasNode node) {
  final h = node.data as WidgetInstance?;
  final p = h?.properties['height']?.mapOrNull(literal: (b) => b.value);
  return (p as num?)?.toDouble() ?? kDefaultNodeHeight;
}

class LayerPanel extends ConsumerWidget {
  const LayerPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(sceneModelProvider);
    final selection = ref.watch(selectionModelProvider);
    final nodes = scene.nodes.toList()..sort((a, b) => b.z.compareTo(a.z));
    // Informational only — overlap is often intentional (a shape behind a
    // gauge, a label over a background), so this is a hint, not a block.
    final overlapping =
        findOverlappingNodes(scene.nodes, _nodeWidth, _nodeHeight);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
              final isLocked = _isLocked(w);
              final overlapsAnother = overlapping.contains(node.id);

              return Container(
                key: ValueKey(node.id),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.4)
                      : null,
                  border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.3)),
                  ),
                ),
                // ListTile paints its own background/ink on the nearest
                // Material ancestor — without this, the Container's own
                // background above hides them (a latent bug that never
                // surfaced while the layer panel was only shown when
                // explicitly toggled on).
                child: Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      kindIcon(kind),
                      size: 18,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            kind.capitalize(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isVisible ? null : Colors.grey,
                            ),
                          ),
                        ),
                        if (overlapsAnother) ...[
                          const SizedBox(width: 4),
                          Tooltip(
                            message:
                                'Overlaps another widget — often fine, but '
                                'check nothing important is hidden underneath',
                            // Neutral info icon, not a warning triangle — the
                            // message itself says this is often fine, so the
                            // icon shouldn't visually signal a problem (same
                            // Icons.info_outline used elsewhere in Studio for
                            // this severity, e.g. studio_settings_screen.dart).
                            child: Icon(
                              Icons.info_outline,
                              size: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '#${node.z} · ${node.id.substring(0, 8)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            isLocked ? Icons.lock : Icons.lock_open,
                            size: 16,
                            color: isLocked
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          tooltip: isLocked
                              ? 'Unlock (allow selecting on canvas)'
                              : 'Lock (skip on canvas clicks)',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _toggleLocked(ref, node, w, !isLocked);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isVisible ? Icons.visibility : Icons.visibility_off,
                            size: 16,
                          ),
                          tooltip: isVisible ? 'Hide' : 'Show',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _toggleVisible(ref, node, w, !isVisible);
                          },
                        ),
                      ],
                    ),
                    // Locked layers can still be selected from this list —
                    // locking only affects canvas clicks, matching how a real
                    // user would expect to reach a widget they intentionally
                    // locked in place.
                    onTap: () {
                      selection.setAll([node.id]);
                    },
                  ),
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

  bool _isLocked(WidgetInstance? w) {
    if (w == null) return false;
    return w.properties['locked']
            ?.mapOrNull(literal: (b) => b.value as bool?) ??
        false;
  }

  void _toggleLocked(
      WidgetRef ref, CanvasNode node, WidgetInstance? w, bool value) {
    final scene = ref.read(sceneModelProvider);
    final props = Map<String, Binding>.from(w?.properties ?? {});
    props['locked'] = Binding.literal(value: value);
    final kind = w?.kind ?? 'text';
    final updated = (w ?? WidgetInstance(id: node.id, kind: kind))
        .copyWith(properties: props);
    scene.upsert(node.copyWith(data: updated));
    ref.read(isDirtyProvider.notifier).state = true;
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
