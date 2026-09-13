# Veschub Roadmap

Last updated: 2026-09-13 (Studio UX audit findings updated same day)

## Legend

- `[P0]` — Blocking / must-do-next
- `[P1]` — Important / next milestone
- `[P2]` — Nice to have / lower priority
- `[P3]` — Future / deferred
- `[SIDETRACKED]` — Intentionally paused; pick up later, not blocking anything below it

## Guiding principle (2026-09-13)

**People create dashboards using Studio's own tools — not by hand-editing
JSON, and not by asking an AI to do it for them.** Every fix in this project
should ultimately show up as something a human can do themselves in the
Studio UI (drag, resize, snap, pick from a categorized property panel).
When a bug is found in example-dashboard JSON, fixing the JSON directly is
fine for that one file, but it doesn't count as "done" unless the underlying
Studio tool (canvas snapping, resize handles, overlap awareness, property
inspector, etc.) would let a real user fix or avoid the same problem without
touching JSON. This is also why the AI Dashboard Assistant (Milestone 9)
stays deprioritized: it's the opposite direction from this goal. At the same
time, remember not everyone wants a maximalist car-cluster replica — some
users want a dashboard with only the 2-3 numbers they care about, so
"simple" needs to be a first-class, easy-to-reach outcome, not just
"advanced" templates with fewer widgets on them.

## Current priority order (revised 2026-09-13)

Milestone numbers below are historical, not priority order. The AI assistant
(Milestone 9) is **not** the current focus — it's a later nice-to-have.
Right now, the priority is entirely: make Studio itself good enough that an
amateur or a professional can freely build dashboards like the real-world
references in `/home/volkan/Pictures/AIdashboards` (Tesla, Porsche Taycan,
BMW, Audi, VW, Ford, CarPlay, Android Auto, and the existing VESC Tool /
Kukirin mobile dashboard) — without the tool itself getting in the way.
Also keep SimHub in mind as a UX bar: a beginner-friendly tool with simple,
clean default widgets and properties that are easy to find and adjust.

1. **Milestone 5 + 10** — Studio Polish & Independent Creation/Ease of Use
   (merged in practice — see "Studio UX audit findings" below for what's
   concretely wrong today)
2. Milestones 4, 6, 7 — as they come up
3. **Milestone 9 (AI Dashboard Assistant)** — deprioritized, revisit once
   Studio itself is in good shape
4. **Milestone 3 (Real Hardware)** — sidetracked, resume once the above is solid

## Studio UX audit findings (2026-09-13)

Found by actually launching `apps/studio` (`flutter run -d linux --release`)
and reading `apps/studio/lib/editor/studio_editor.dart` (2,676 lines — the
main editor file), compared against the reference dashboards.

- [x] **FIXED**: `apps/studio/pubspec.yaml` was missing
      `flutter: uses-material-design: true` (present in `apps/dashboard`,
      never added here). Every icon in the widget palette and toolbar was
      rendering as a garbled fallback glyph — confirmed by screenshot before
      and after. This alone was likely the single biggest "why does this
      look broken/confusing" contributor. Also fixed 4 icon collisions
      found while verifying (gauge/digitalspeed, bar/statusbar,
      status/tripstats, power/power_flow all shared one icon).
- [x] **FIXED**: **Widget palette has no search or categories.** Added a
      search field (filters by kind or template-variant name) and grouped
      the default view into 6 categories (Gauges & Meters, Text & Data,
      Charts, Car Status, Media & Controls, Custom) covering all 22 kinds,
      with an "Other" fallback bucket so a future uncategorized kind can't
      silently disappear. See `apps/studio/lib/editor/studio_palette.dart`.
- [x] **FIXED**: **`studio_editor.dart` was a 2,676-line god-file.** Split
      into `studio_editor.dart` (main widget only), `studio_palette.dart`
      (palette + `_templates` preset data), `studio_canvas_area.dart`
      (drop-target canvas), and `studio_inspector.dart` (properties
      inspector + all binding editors) — joined via `part`/`part of` so no
      private members needed renaming. Verified with `flutter analyze`
      (no new issues) and `flutter test` (22/22 pass) both before and
      after.
- [ ] [P2] **Inspector empty state wastes the whole right panel** — "Select
      a widget to edit its properties" with nothing else. Consider a
      collapsed/narrow empty state, or defaulting to canvas-level properties
      (size, background) when nothing is selected.
- [ ] [P2] **Toolbar icons have no visible labels** — undo/redo, new/open/
      save/export, settings, and layers are all icon-only in the top-right
      toolbar. Tooltips may exist on hover but a first-time user scanning
      the bar can't tell them apart at a glance; consider a labeled overflow
      menu for the less-frequent ones (export, settings) and keep only
      undo/redo/save as bare icons.

## Widget rendering audit (2026-09-13)

Rendered all 9 example dashboards through `tools/dashboard_renderer`
(build it once with `flutter build linux --release` in that directory,
then run the compiled binary directly — `flutter run` mangles CLI args
passed to the app, treating the first one as a `--target` override).

- [x] **FIXED — major**: **Gauge needle collided with the centered digital
      readout, rendering as a "horrendous" white teardrop blob.** Every
      needle-style gauge (BMW Amber, Audi Sport, Porsche Green, and any
      plain gauge with `showCenterText: true`) drew a wide needle base +
      two-circle hub from dead-center, landing directly under the big
      number. Fixed in `gauge_widget.dart` (`avoidCenter` on
      `_GaugePainter`): the needle now starts partway out and skips the
      hub when a digital readout owns the center. This alone fixed the
      dominant visual defect across nearly every rendered example.
- [x] **FIXED**: `vw_digital.veschub.json`'s two trip-info pods were
      centered on the exact same point as their gauge's own center-value
      text — moved and shrunk to sit below the readout instead.
- [x] [P1] **Canvas overlap awareness** (2026-09-13) — `findOverlappingNodes`
      in `editor_canvas`'s `hit_test.dart` + an amber warning icon next to
      any overlapping layer in the layer panel. A hint, not a block — see
      `editor_canvas/test/editor_canvas_test.dart`. A canvas-level visual
      highlight (not just the layer panel) is a possible future follow-up
      if the layer-panel hint proves insufficient in practice.
- [x] **All 22 widget kinds individually audited** (2026-09-13, second
      pass): rendered one instance of every registered kind side by side
      via a generated showcase dashboard through `tools/dashboard_renderer`.
      Found and fixed three more real issues:
  - [x] **FIXED**: `bar`'s track had no border — at low/zero values it was
        nearly invisible against a similarly dark background. Added a
        visible outline regardless of fill level.
  - [x] **FIXED**: `image` had no `errorBuilder` on `Image.asset`/
        `Image.network` — a missing/invalid `src` rendered as a silent
        blank box. Now falls back to the same broken-image icon already
        used for a null `src`. (Also confirmed the built-in Image presets'
        `assets/images/placeholder.png` path doesn't exist and isn't
        declared in any pubspec — every fresh Image widget hits this
        fallback until a user supplies a real path; that's expected, not
        a bug, but worth remembering if this surprises someone.)
  - [x] **FIXED**: Studio palette's `paint > Custom` preset shipped an
        empty program (renders nothing at all), while the bare-default
        fallback elsewhere in the same file already had a good starter
        program (`_samplePaintProgram`) — palette preset now uses it too.
  - **Not a bug**: `chart` appeared blank in the one-shot showcase
        render — by design it needs 2+ samples in its rolling history
        before it draws a line, and a static single-frame render never
        gets a second sample. The real running dashboard app updates
        telemetry continuously, so this doesn't reproduce there.
  - Remaining, not fixed: `warnings` shows icons with no text labels
        (low clarity — a beginner may not know what the icons mean without
        hovering/guessing); `power_flow` is visually very thin/minimal
        compared to its neighbors. Neither is broken, just weak.
- [ ] [P2] **Need genuinely minimal starter widgets, not just car-brand
      replicas.** Current templates lean toward maximalist car-cluster
      looks. Add plain/minimal variants (e.g. a bare "just the number"
      text style, an undecorated thin-bar) for users who want a dashboard
      with only the 2-3 values they care about — a SimHub-style simple
      option alongside the styled ones, not a replacement for them.

## Full test sweep (2026-09-13)

Ran `flutter test` in every package/app with a `test/` directory (melos'
own `test` script needs a bare `dart` on PATH, which isn't set up in this
shell — looped manually instead). **228/228 tests pass** across
`app_integration`, `dashboard_model`, `dashboard_runtime`,
`dashboard_storage`, `editor_canvas`, `node_graph`, `paint_dsl`,
`settings`, `templates`, `vesc_proto`, `vesc_telemetry`, `vesc_transport`,
`widgets_library` (102), `apps/dashboard`, `apps/studio` (23, including
the new end-to-end drag/select/inspect flow).

- [ ] [P1] **`packages/node_graph_editor` has zero test files** — 466 lines
      of interactive Flow-mode canvas code (drag nodes, connect sockets,
      delete edges) with no automated coverage at all. This is the
      biggest test-coverage gap in the monorepo.

## SimHub UX research (2026-09-13)

Cloned `https://github.com/SHWotever/SimHub.wiki.git` directly (rather
than a summarized fetch) to read the Dash Studio docs/tutorial and view
the actual editor GIFs — SimHub is a widely-used, beginner-friendly
competitor in the same space. Read: Dash-Studio.md, ---Creation-Tutorial,
-Editor-Overview, ---Bindings, -Designer-Shortcuts, -Overlays,
-performance. Concrete findings applied this session:

- [x] **Layer locking with click-through**, closing the item above.
- [x] **Layers list permanently visible above the property grid**
      (previously a toggle swapped the whole right panel between the two
      — see the "guiding principle" note above about tools people can
      use themselves; not being able to see your layer list while editing
      properties is exactly the kind of friction that principle is about).
- [x] **Only one property section starts expanded**, not all four at
      once — SimHub's own grid is mostly flat and what few collapsible
      groups it has default open, so the closer read of the ask is
      "don't dump everything expanded on every selection," not "closed by
      default."
- Not yet applied, worth a future pass:
  - SimHub's binding indicator is a *single* icon per property whose
    color encodes state (gray = static, green = bound) that opens an
    editor popup on click — more compact than our 4 always-visible
    Lit/Tel/F(x)/Graph chips per row. Worth revisiting if the inspector
    still feels dense once the above lands.
  - "Smart" pre-bound components (SimHub's Gear widget works with zero
    configuration the instant it's added) — most of our palette presets
    already do this (bound to a sensible telemetry key), but it's worth
    an explicit audit pass to confirm every preset qualifies, especially
    any added going forward.
  - SimHub keyboard shortcuts (`ctrl+a` select all, arrow keys nudge,
    `ctrl+alt+arrow` resize, `del` delete) — overlaps with the existing
    "Keyboard shortcuts" P2 item in Milestone 5, not newly discovered but
    now backed by a concrete reference list.
  - Multi-screen dashboards (SimHub dashboards can have multiple
    screens/pages you switch between) — a bigger feature, not scoped.

---

## Milestone 1: Studio MVP ✅

- [x] Drag-drop widgets onto canvas
- [x] Property inspector with literal / telemetry / graph bindings
- [x] Editor canvas: move, resize, snap, undo/redo
- [x] Save / load dashboards (SQLite)
- [x] Template gallery with live previews
- [x] Capability-level gating (Basic / Advanced / Expert) — lives in `packages/settings`
      (default `basic`) + `PropertyMeta.minLevel`; selector moved from the canvas
      toolbar into Studio Settings. Kept as-is; the AI assistant (Milestone 9) does
      not respect this gate — it can set any manifest-valid property regardless of
      the human's current level.
- [x] Flow mode: node-graph editor with DragTarget
- [x] Paint DSL: declarative custom-paint widget
- [x] 11 widget kinds: gauge, bar, text, status, chart, image, web, paint,
      minigauge, digitalspeed, music, tripstats, power_flow, warnings, appgrid,
      statusbar, climate, car_viz, map, battery_range, gear_selector
- [x] Property manifests categorized (Visuals / Data Bindings / Layout & Spacing /
      Fonts & Colors) across all widget kinds, with tooltips, sliders, hex color
      entry, and out-of-the-box defaults + starter templates (see `PROJECT.md`,
      `TEST_INFRA.md`)

## Milestone 2: Dashboard Runtime ✅

- [x] VESC telemetry ingestion (14 of 18 keys)
- [x] Widget rendering in dashboard viewer
- [x] Cosmetic properties: backgroundColor, borderRadius, fontSize
- [x] Formula bindings: math expression evaluator (F(x) toggle)
- [x] Expandable inspector sections (Advanced / Expert)
- [x] JSON export / import (.veschub.json)
- [x] Pipeline integration tests (3 tests)
- [x] Settings: transport, auto-connect, data rate
- [ ] [P2] Flow mode: add script/Dart-expression tab alongside node graph
- [ ] [P2] Flow mode: node-graph export/import, presets, documentation

## Milestone 3: Real Hardware [SIDETRACKED]

Paused deliberately — everything else in this roadmap (Studio polish, AI
assistant, templates) only needs `vesc_sim` and doesn't touch real transports.
Pick this back up once the UI/tooling/AI tracks below are in good shape.

- [ ] [SIDETRACKED] BLE transport adapter (`packages/vesc_transport`)
- [ ] [SIDETRACKED] USB-serial transport adapter
- [ ] [SIDETRACKED] Transport auto-detection (scan + connect flow)
- [ ] [SIDETRACKED] Manual connect / disconnect UI in dashboard
- [ ] [SIDETRACKED] Transport status indicator with error recovery
- [ ] [SIDETRACKED] Connection timeout + retry logic

## Milestone 4: Dashboard Viewer Polish 🚧

- [ ] [P1] Telemetry ingestion for remaining 4 keys (foc.id, foc.iq)
- [x] [P1] Per-widget size from document (via properties approach, no schema migration)
- [ ] [P2] Dark / light theme obeying widget background colors
- [ ] [P2] Metric / imperial unit conversion (per-widget, not global)
- [ ] [P3] Dashboard app display modes: fullscreen, splitscreen, Pi-optimized

## Milestone 5: Studio Polish 🚧

- [x] [P0] Grid layout + snap (toggleable grid overlay, magnetic edge snap to grid + canvas center/boundaries)
- [x] [P0] Canvas custom width/height input (WxH text fields replace HD/FHD/QHD presets)
- [x] [P0] Widgets opaque by default with configurable background color
- [x] [P1] Widget borders / shadows (borderWidth, borderColor, shadowColor, shadowBlur, shadowOffsetY)
- [x] [P1] More gauge properties: tickCount, sweepAngle, startAngle, arcWidth, needleStyle
- [x] [P1] More chart properties: lineWidth, showGrid, gridColor, smoothCurve, fillArea, fillColor
- [x] [P1] More font properties: fontWeight, letterSpacing
- [x] [P1] More cosmetic: opacity, padding, width, height, visible — across all 7 widget kinds
- [x] [P0] Manifest-vs-renderer audit test (2026-09-13) — found and fixed
      4 real gaps on first run (fontFamily/fontWeight/letterSpacing missing
      from 13 kinds, web missing backgroundColor, minigauge's orientation
      completely undeclared). See `widgets_library/test/manifest_matches_renderer_test.dart`.
- [ ] [P1] Rotation handle on canvas + rotation property/field in the inspector
      (parallel to `_PositionFields`), plus an anchor point for resize/rotate
- [ ] [P1] Bar properties: barRadius, showValue, gradient, gradientColor
- [x] [P1] Multiple selection with group operations (2026-09-13) — group-move
      already worked (TransformNodesCommand always applied to the whole
      selection), but there was no way to build a multi-selection one
      click at a time. Added shift/ctrl/cmd-click toggle via
      `SelectionModel.toggle()` (existed, was never called); plain click
      on something outside the selection now replaces it instead of adding.
- [x] [P2] Layer panel: reorder widgets by z-height, visibility toggle
- [x] [P2] Layer panel: per-layer lock (2026-09-13, see "SimHub UX
      research" below) — locking skips a widget entirely during canvas
      hit-testing (click/marquee) while it stays selectable from the
      layer row itself.
- [x] [P2] Cut / copy / paste between dashboards (2026-09-13) —
      `NodeClipboard` was fully built and tested but never wired to any
      UI; now bound to Ctrl/Cmd+C/X/V. In-memory, session-scoped, so it
      survives switching to a different dashboard document.
- [x] [P2] Keyboard shortcuts: delete, copy, undo, redo (2026-09-13) — plus
      select-all and arrow-key nudge, matching SimHub's documented set.
      See `apps/studio/lib/editor/keyboard_shortcuts.dart` — note the
      explicit typing-guard needed because `CallbackShortcuts` did not
      reliably defer to a focused text field on its own (verified by a
      failing test before the fix).
- [ ] [P2] Golden-screenshot regression tests via `tools/dashboard_renderer`,
      using the 9 example dashboards as visual baselines
- [ ] [P3] Dashboard description rich text / markdown
- [ ] [P3] App-wide icon audit pass (studio + dashboard chrome) — icons have
      been flagged twice as inconsistent; do this as one deliberate pass,
      not per-widget patches

## Milestone 6: Navigation & GPS 🚧

- [ ] [P2] GPS widget (speed, altitude, coordinates)
- [ ] [P2] Map widget (OpenStreetMap tile layer)
- [ ] [P2] GPX import / export
- [ ] [P3] Route planning overlay
- [ ] [P3] Trip recording with replay

## Milestone 7: Production Readiness 🚧

- [ ] [P1] Android release build (APK signing)
- [ ] [P2] Windows / macOS release builds
- [ ] [P2] CI: version bumping + changelog generation
- [ ] [P2] Crash reporting (Sentry or similar)
- [ ] [P3] OTA dashboard updates (fetch from server)

## Milestone 8: VESC Package Manager Integration 🚧

- [ ] [P3] Dashboard → Qt VESC Package Manager converter
- [ ] [P3] Two-way sync: edit on mobile, deploy to VESC Tool
- [ ] [P3] VESC Tool LispBM script export from Flow/Script mode

## Milestone 9: AI Dashboard Assistant 🚧

Full design in `AI_ASSISTANT.md`. Studio-only, cloud (Claude API); the
Dashboard runtime app never depends on it. Every AI action goes through the
existing `editor_canvas` command stack (`AddNodeCommand`, `UpdateNodeDataCommand`,
`TransformNodesCommand`, ...) so it's undoable and validated against
`property_manifest.dart` exactly like a manual edit — no separate write path.

- [ ] [P0] `packages/ai_assistant`: Claude API client + tool-use schema mapped
      1:1 to `EditorCommand` subclasses
- [ ] [P0] System-prompt context builder: current document JSON, widget kind
      manifests, `TelemetryKey.all`, available templates
- [ ] [P0] Guidance mode: chat/suggestion panel in Studio; each AI turn proposes
      a small batch of tool calls the user reviews before they commit
- [ ] [P1] Auto mode: prompt → full `DashboardDocument` generation (agentic
      multi-tool-call loop), applied as one reviewable/undoable batch
- [ ] [P1] Mode toggle in Studio UI (alongside Template/Canvas/Flow)
- [ ] [P1] Guardrails: manifest validation, canvas-bounds clamping, min/max
      clamping — reuse existing clamp logic rather than re-implementing
- [ ] [P2] API key entry + storage in Studio Settings (`packages/settings`)
- [ ] [P2] Guidance-mode inline hints (e.g. "this text widget has no binding")
      independent of chat, surfaced directly in the inspector
- [ ] [P3] Auto mode: "match this reference image" (reuses the AIdashboards
      car-brand screenshot workflow, now available to any user prompt)

## Milestone 10: Independent Creation & Ease of Use 🚧

The goal: someone with zero familiarity with the app can open Studio and
build a working dashboard without external help — before AI is even involved.
This is largely Milestone 5 items viewed through a "first-run" lens, plus a
few net-new pieces.

- [ ] [P1] First-run onboarding: guided "build your first dashboard" flow
      (distinct from the AI assistant — pure UI walkthrough)
- [ ] [P1] Per-widget unit system: unit chosen per property (speed: km/h · mph ·
      m/s; temp: °C · °F · K; etc.), replacing the global metric/imperial
      toggle — reuse existing format-helper functions in `dashboard_model`
- [ ] [P1] Template gallery: "start from a template, then tweak" made the
      default landing experience (Template mode already supports this —
      make it the first thing a new user sees)
- [ ] [P2] Contextual tooltips/help already added for property rows (see
      `PROJECT.md` #5) — extend the same pattern to canvas tools and palette
- [ ] [P2] Smart-default widget sizing/positioning when dropped on canvas
      (avoid overlap, snap to nearest empty grid cell)
- [ ] [P3] In-app "what does this property do" examples/preview thumbnails

---

## Quick reference

### Tools & commands
```sh
melos bootstrap          # Install deps
melos run build_runner   # Regenerate freezed/generated code
melos run test           # All tests
flutter run -d linux     # Run on desktop
flutter build linux --release  # Production build
```

### Key files
| File | Purpose |
|------|---------|
| `apps/studio/lib/editor/studio_editor.dart` | Main editor UI |
| `apps/dashboard/lib/main.dart` | Dashboard runtime/viewer |
| `packages/widgets_library/lib/src/property_manifest.dart` | Widget property definitions |
| `packages/dashboard_model/lib/src/document.dart` | Document schema |
| `packages/dashboard_runtime/lib/src/dashboard_runtime.dart` | Binding resolver |
| `packages/vesc_transport/lib/src/transport.dart` | Transport abstraction |
