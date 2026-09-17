/// Keyboard shortcuts for Canvas mode: delete, copy/cut/paste, undo/redo,
/// select all, and arrow-key nudge. None of this existed before — the
/// clipboard (packages/editor_canvas's NodeClipboard) was fully built and
/// tested but never wired to any UI, and there was no keyboard handling
/// anywhere in the app.
///
/// IMPORTANT: [CallbackShortcuts] does NOT defer to a focused text field's
/// own key handling in this app — once a [SingleActivator] is bound, the
/// key event is consumed the moment the activator matches, *before* it can
/// reach a descendant [EditableText]'s own backspace/delete-character
/// handling, even if the bound callback itself is a no-op. A guard inside
/// the callback (an earlier version of this file) stopped Backspace from
/// deleting the whole widget while typing, but the keystroke was still
/// swallowed either way — so it also silently disabled backspace *inside*
/// every property text field. The fix has to omit the Delete/Backspace
/// bindings entirely while a text field has focus, so the keystroke is
/// never claimed and falls through to the field's own editing. Since
/// [CallbackShortcuts]' binding map is static per build, this widget
/// listens to [FocusManager] and rebuilds on every focus change so the map
/// stays current.
library;

import 'package:editor_canvas/editor_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/editor_providers.dart';

/// True while an [EditableText] (TextField/TextFormField) holds focus.
bool _typing() {
  final focused = FocusManager.instance.primaryFocus;
  return focused?.context?.findAncestorWidgetOfExactType<EditableText>() !=
      null;
}

class CanvasKeyboardShortcuts extends ConsumerStatefulWidget {
  final Widget child;
  const CanvasKeyboardShortcuts({required this.child, super.key});

  @override
  ConsumerState<CanvasKeyboardShortcuts> createState() =>
      _CanvasKeyboardShortcutsState();
}

class _CanvasKeyboardShortcutsState
    extends ConsumerState<CanvasKeyboardShortcuts> {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final typing = _typing();
    return CallbackShortcuts(
      bindings: {
        // Omitted entirely while typing, not just guarded — see the class
        // doc comment for why a guard alone isn't enough.
        if (!typing) ...{
          const SingleActivator(LogicalKeyboardKey.delete): () =>
              _deleteSelected(ref),
          const SingleActivator(LogicalKeyboardKey.backspace): () =>
              _deleteSelected(ref),
        },
        const SingleActivator(LogicalKeyboardKey.keyC, control: true): () =>
            _guarded(() => _copySelected(ref)),
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true): () =>
            _guarded(() => _copySelected(ref)),
        const SingleActivator(LogicalKeyboardKey.keyX, control: true): () =>
            _guarded(() => _cutSelected(ref)),
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true): () =>
            _guarded(() => _cutSelected(ref)),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
            _guarded(() => _paste(ref)),
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () =>
            _guarded(() => _paste(ref)),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            _guarded(() => ref.read(commandStackProvider).undo()),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
            _guarded(() => ref.read(commandStackProvider).undo()),
        const SingleActivator(LogicalKeyboardKey.keyZ,
                control: true, shift: true):
            () => _guarded(() => ref.read(commandStackProvider).redo()),
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            () => _guarded(() => ref.read(commandStackProvider).redo()),
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
            _guarded(() => ref.read(commandStackProvider).redo()),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () =>
            _guarded(() => ref
                .read(selectionModelProvider)
                .setAll(ref.read(sceneModelProvider).nodes.map((n) => n.id))),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () =>
            _guarded(() => ref
                .read(selectionModelProvider)
                .setAll(ref.read(sceneModelProvider).nodes.map((n) => n.id))),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(0, -1))),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(0, 1))),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(-1, 0))),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(1, 0))),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(0, -10))),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(0, 10))),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(-10, 0))),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () =>
            _guarded(() => _nudgeSelected(ref, const Offset(10, 0))),
      },
      child: Focus(autofocus: true, child: widget.child),
    );
  }

  static void _guarded(void Function() action) {
    if (_typing()) return;
    action();
  }

  void _deleteSelected(WidgetRef ref) {
    final scene = ref.read(sceneModelProvider);
    final selection = ref.read(selectionModelProvider);
    if (selection.isEmpty) return;
    final nodes =
        selection.ids.map((id) => scene[id]).whereType<CanvasNode>().toList();
    if (nodes.isEmpty) return;
    ref.read(commandStackProvider).execute(RemoveNodesCommand(nodes));
    selection.clear();
    ref.read(isDirtyProvider.notifier).state = true;
  }

  void _copySelected(WidgetRef ref) {
    final scene = ref.read(sceneModelProvider);
    final selection = ref.read(selectionModelProvider);
    if (selection.isEmpty) return;
    final nodes = selection.ids.map((id) => scene[id]).whereType<CanvasNode>();
    ref.read(nodeClipboardProvider).copy(nodes);
  }

  void _cutSelected(WidgetRef ref) {
    _copySelected(ref);
    _deleteSelected(ref);
  }

  void _paste(WidgetRef ref) {
    final clipboard = ref.read(nodeClipboardProvider);
    if (clipboard.isEmpty) return;
    final idGen = ref.read(idGeneratorProvider);
    final pasted = clipboard.paste(idGen.next);
    for (final node in pasted) {
      ref.read(commandStackProvider).execute(AddNodeCommand(node));
    }
    ref.read(selectionModelProvider).setAll(pasted.map((n) => n.id));
    ref.read(isDirtyProvider.notifier).state = true;
  }

  void _nudgeSelected(WidgetRef ref, Offset delta) {
    final scene = ref.read(sceneModelProvider);
    final selection = ref.read(selectionModelProvider);
    if (selection.isEmpty) return;
    final changes = <String, (Matrix4, Matrix4)>{};
    for (final id in selection.ids) {
      final node = scene[id];
      if (node == null) continue;
      final oldT = node.transform.clone();
      final newT = Matrix4.copy(node.transform)
        ..setEntry(0, 3, node.transform.entry(0, 3) + delta.dx)
        ..setEntry(1, 3, node.transform.entry(1, 3) + delta.dy);
      changes[id] = (oldT, newT);
    }
    if (changes.isEmpty) return;
    ref.read(commandStackProvider).execute(TransformNodesCommand(changes));
    ref.read(isDirtyProvider.notifier).state = true;
  }
}
