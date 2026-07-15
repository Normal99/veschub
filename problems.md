# Bugs, errors and potential changes

## Fixed ✅

**1. Dragging and dropping position** — widgets popping up in the wrong area or off-screen.
> **Status: FIXED** — `_CanvasArea` converted to `ConsumerStatefulWidget` with a `GlobalKey` on the `DragTarget`. `_toCanvasPosition()` method converts the drag event's global coordinates to local canvas space via `globalToLocal()` before creating the node transform. Also added visible border outline so the drop zone is obvious.

**2. Web widget crash** — `InAppWebViewPlatform.instance` assertion failure when dragging a web widget onto the canvas.
> **Status: FIXED** — `packages/widgets_library/lib/widgets/web_widget_io.dart:14` — the `InAppWebView` constructor is now wrapped in a `try/catch`. If the platform webview is unavailable (e.g. Linux desktop without the required libraries), it falls back to a themed placeholder panel showing the URL and an "unavailable" message. The original error trace is preserved below for reference.

**3. Canvas no outlines** — the drop zone was invisible, users couldn't tell where the canvas was.
> **Status: FIXED** — `EditorCanvas` wrapper now has a `BoxDecoration` with `Border.all(color: Theme.of(context).colorScheme.outline, width: 2)`. The border turns blue when a drag is hovering over the canvas.

**4. Canvas aspect ratio** — no way to configure the canvas for different device shapes (16:9, 9:16, etc.).
> **Status: FIXED** — added a horizontal-scrollable row of `ActionChip` aspect-ratio presets above the canvas: `16:9`, `9:16`, `4:3`, `1:1`, `2.35:1`. The active preset is highlighted. The current size is shown to the right. Changing the preset updates `canvasSizeProvider` and marks the document dirty.

**5. Widget icons don't show up** — all palette items used `Icons.widgets`.
> **Status: FIXED** — `_PaletteTile` now maps widget kinds to specific icons: `gauge` → `Icons.speed`, `bar` → `Icons.bar_chart`, `text` → `Icons.text_fields`, `chart` → `Icons.show_chart`, `status` → `Icons.info_outline`, `image` → `Icons.image`, `web` → `Icons.public`, `paint` → `Icons.brush`. Falls back to `Icons.widgets` for unknown kinds.

**6. Manual telemetry key input** — value binding dropdown only offered canonical keys.
> **Status: FIXED** — `_TelemetryEditor` now has a "Manual" button that switches from dropdown to free-form text input. Typing any key and submitting commits it via the same `UpdateNodeDataCommand` pipeline. Useful for custom/debug keys not listed in `TelemetryKey.all`.

---

## Needs verification (test at runtime)

**7. Moving widgets is wonky** — widgets sometimes don't move correctly.
> **Status: ADDRESSED** — the drag-drop coordinate fix (item #1) applies to initial placement. The EditorCanvas itself handles moves via `TransformNodesCommand` in `_onPanEnd`, which uses the snap delta and the start transform (captured at drag start). This was also fixed to pre-multiply translations to avoid rotated-local-space issues. **Needs manual testing in the running studio app.**

**8. Template previews (thumbnails)** — thumbnails not rendering.
> **Status: NOT YET FIXED** — `_LivePreview` in template_mode.dart renders a static `SizedBox` with `buildWidget()` against a mock `TelemetryStore` seeded with sample values. The preview should render but may need investigation if the `TelemetryStore` isn't properly initialised or the widget sizes are too small in the card. **Needs manual testing.**

---

## Deferred (design/planning — not bugs)

**9. Flow mode purpose** — user wants a "standard script section" for experts instead of / in addition to the node-graph flow editor.
> **Status: PLANNING** — added to `FUTURE_FEATURES.md`. The node-graph editor (Flow mode) is working but its purpose may not be obvious. A simpler script/Dart-code injection slot for Expert users is something to design in a future iteration.

**10. Settings page is dry** — needs more options.
> **Status: DEFERRED** — current settings have Theme (system/light/dark) and Capability Level. Potential additions: default canvas size, default transport, metric/imperial units, data rate limiter, auto-connect toggle. Low priority — add when those features are implemented.

**11. Widgets need more cosmetic customizations** — e.g. borders, shadows, font choices, more color slots.
> **Status: DEFERRED** — property manifests can be extended with additional properties per widget kind without breaking existing documents. Each new property needs: a `PropertyMeta` entry in `property_manifest.dart`, a `visibleProperties` filter, and render logic in the widget's build method. Low priority — add incrementally.

**12. Basic/Advanced/Expert capability gating** — user wants to replace mode-gating with expandable subsections in the inspector.
> **Status: DEFERRED** — current design uses `CapabilityLevel` enum to hide/show entire property groups and lock transforms. The proposed UX (putting advanced options under expandable sections) would mean fewer "modes" and is a valid design direction. Not a bug — needs a design decision before implementation.

---

## Original web widget error trace (for reference)

```
══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY ╞═══════════════════════════════════════════════════════════
The following assertion was thrown building WebWidget(dirty):
A platform implementation for `flutter_inappwebview` has not been set. Please ensure that
an implementation of `InAppWebViewPlatform` has been set to `InAppWebViewPlatform.instance` before use.
...
When the exception was thrown, this was the stack:
#5      buildWebEmbed (package:widgets_library/widgets/web_widget_io.dart:14:10)
#6      WebWidget.build (package:widgets_library/widgets/web_widget.dart:37:25)
...
════════════════════════════════════════════════════════════════════════════════════════════════════
```
