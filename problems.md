# Bugs, errors and potential changes

## Fixed ✅

**1. Dragging and dropping position** — widgets popping up in the wrong area or off-screen.
> **Status: FIXED (x2)** — Original fix: converted `_CanvasArea` to `ConsumerStatefulWidget` with `GlobalKey` + `globalToLocal()`.
> **Refix**: `_toCanvasPosition` now uses `_canvasKey` on a container **inside** the `FittedBox`, so `globalToLocal` correctly accounts for FittedBox scaling. `DragTarget` is also inside the `FittedBox`+`SizedBox` so drops are only accepted on canvas area.

**2. Web widget crash** — `InAppWebViewPlatform.instance` assertion failure when dragging a web widget onto the canvas.
> **Status: FIXED** — `packages/widgets_library/lib/widgets/web_widget_io.dart:14` — the `InAppWebView` constructor is now wrapped in a `try/catch`. If the platform webview is unavailable (e.g. Linux desktop without the required libraries), it falls back to a themed placeholder panel showing the URL and an "unavailable" message. The original error trace is preserved below.

**3. Canvas outline not reflecting actual canvas bounds** — on 16:10 monitors with 16:9 aspect ratios (HD/FHD/QHD), the border was on the outer container, which letterboxes via FittedBox. The border rectangle didn't match the visible canvas edge.
> **Status: FIXED** — the border `BoxDecoration` is now on the canvas-sized `Container` inside the `FittedBox`. The outer `Container` only handles the letterbox background color. The border now exactly traces the canvas bounds regardless of aspect ratio or window size.

**4. Canvas aspect ratio** — no way to configure the canvas for different device shapes (16:9, 9:16, etc.).
> **Status: FIXED** — added a horizontal-scrollable row of `ActionChip` aspect-ratio presets above the canvas: `HD` (1280×720), `FHD` (1920×1080), `QHD` (2560×1440), `4:3` (1024×768), `1:1` (800×800). The active preset is highlighted. An orientation toggle button swaps width↔height. Changing the preset updates `canvasSizeProvider` and marks the document dirty. EditorCanvas wrapped in `FittedBox`+`SizedBox(canvasSize)` so the canvas visually resizes.

**5. Widget icons don't show up** — all palette items used `Icons.widgets`.
> **Status: FIXED** — `_PaletteTile` now maps widget kinds to specific icons: `gauge` → `Icons.speed`, `bar` → `Icons.bar_chart`, `text` → `Icons.text_fields`, `chart` → `Icons.show_chart`, `status` → `Icons.info_outline`, `image` → `Icons.image`, `web` → `Icons.public`, `paint` → `Icons.brush`. Falls back to `Icons.widgets` for unknown kinds.

**6. Manual telemetry key input** — value binding dropdown only offered canonical keys.
> **Status: FIXED** — `_TelemetryEditor` now has a "Manual" button that switches from dropdown to free-form text input. Typing any key and submitting commits it via the same `UpdateNodeDataCommand` pipeline. Useful for custom/debug keys not listed in `TelemetryKey.all`.

**7. Moving widgets is wonky** — widgets sometimes don't move correctly.
> **Status: FIXED** — EditorCanvas moves via `TransformNodesCommand` in `_onPanEnd` using snap delta + start transform, with pre-multiplied translations. Drag operations are smooth and widgets stay correctly positioned.

**8. Template previews (thumbnails)** — thumbnails not rendering in gallery.
> **Status: FIXED** — replaced the description text in `_TemplateCard` with a `_TemplatePreview` widget. Each gallery card now renders a miniature of the template's dashboard document using `FittedBox` + `SizedBox` + `buildWidget()`, scaled to fit the card. Shared `previewTelemetryProvider` seeds mock values so gauges/charts render with data.

**9. Widgets dragged outside canvas boundaries** — no boundary enforcement; widgets could be moved or resized beyond the canvas edge.
> **Status: FIXED** — Added `canvasSize` parameter to `EditorCanvas`. `_clampTransform()` in both `_applyMove()` and `_applyResize()` checks widget bounds against canvas dimensions and shifts widgets back inside if they exceed any edge. If the widget is larger than the canvas, it's left/top-aligned.

---

## Deferred (design/planning — not bugs)

**10. Flow mode purpose** — user wants a "standard script section" for experts instead of / in addition to the node-graph flow editor.
> **Status: ADDRESSED** — Added `Binding.formula` variant to the data model: a math expression (e.g. `erpm / 1000`, `tempMotor - tempMosfet`) evaluated against telemetry keys. Includes a recursive-descent expression evaluator with + - * / ^ operators, parentheses, and telemetry key references. The studio inspector now has a binding type toggle (Lit/Tel/F(x)/Graph) so any property can be switched between literal, telemetry, formula, or graph binding. Formula editor shows a monospaced text field with a placeholder expression. This gives Expert users a code-like binding option without the complexity of the full node graph.

**11. Settings page is dry** — needs more options.
> **Status: DEFERRED** — current settings have Theme (system/light/dark) and Capability Level. Potential additions: default canvas size, default transport, metric/imperial units, data rate limiter, auto-connect toggle. Low priority — add when those features are implemented.

**12. Widgets need more cosmetic customizations** — e.g. borders, shadows, font choices, more color slots.
> **Status: FIXED** — Added `backgroundColor`, `borderRadius`, and `fontSize` properties to all widget manifests (gauge, bar, text, status, chart, image, web). Each widget renderer updated to read and apply these properties from the resolved bindings. Dashboard viewer's `_positioned` also reads `backgroundColor` and `borderRadius` from widget properties instead of hardcoded `Color(0xFF111111)` and `BorderRadius.circular(12)`. Defaults preserved for backward compatibility.

**13. Basic/Advanced/Expert capability gating** — user wants to replace mode-gating with expandable subsections in the inspector.
> **Status: FIXED** — Replaced the capability-level-gated property filter with expandable sections. Basic properties always visible. Advanced and Expert properties grouped into collapsible `_ExpandableSection` widgets (Advanced expanded by default, Expert collapsed). Added `allProperties()` function to property_manifest for unfiltered lookups. Also added a telemetry ingestion completeness fix (14 of 18 keys now ingested, up from 6) and shared widget sizing constants for consistency.

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
