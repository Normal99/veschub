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
- [x] [P2] **Inspector empty state** (2026-09-13) — now shows canvas size,
      background/accent colour swatches, with the "select a widget" hint
      as a footer instead of the only content.
- [x] [P2] **Toolbar icon labels** (2026-09-13) — new/open/export/import/
      settings/layers-toggle moved into a labeled overflow `PopupMenuButton`
      (icon + text per row). Only Undo/Redo/Save remain as bare icons.

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
- [x] [P2] **Genuinely minimal starter widgets** (2026-09-13): added a
      `Minimal` preset each to the `text` and `bar` palette entries in
      `studio_palette.dart` — bare number (transparent background, no
      label, no card chrome) and an undecorated thin fill bar (zero radius,
      zero padding), alongside the existing styled/car-brand presets rather
      than replacing them. `gauge` already had a comparable `Minimal Arc`
      preset from before this session.

## Full test sweep (2026-09-13)

Ran `flutter test` in every package/app with a `test/` directory (melos'
own `test` script needs a bare `dart` on PATH, which isn't set up in this
shell — looped manually instead). **228/228 tests pass** across
`app_integration`, `dashboard_model`, `dashboard_runtime`,
`dashboard_storage`, `editor_canvas`, `node_graph`, `paint_dsl`,
`settings`, `templates`, `vesc_proto`, `vesc_telemetry`, `vesc_transport`,
`widgets_library` (102), `apps/dashboard`, `apps/studio` (23, including
the new end-to-end drag/select/inspect flow).

- [x] [P1] **`packages/node_graph_editor` test coverage** (2026-09-13) —
      5 tests covering drop-from-palette, drag, socket-connect, edge
      delete, node select. Writing the drag test with a realistic
      sidebar-next-to-canvas harness (matching flow_mode.dart's actual
      layout) immediately found a real bug: node dragging mixed local
      pan-start coordinates with global pan-update coordinates, silently
      baking the editor's own screen offset into every drag. Fixed via
      delta-based movement. Textbook case for why this item was flagged
      as the biggest coverage gap.

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

- [x] [P1] Telemetry ingestion for remaining keys (2026-09-13): the roadmap's
      "4 keys" count was stale — only `foc.id`/`foc.iq` were actually missing.
      Root-caused: `vesc_proto`'s `TelemetryValues.fromPayload` already
      decoded them correctly (`id`/`iq` fields, firmware-accurate scale), and
      `vesc_telemetry/ingest.dart`'s `kValuesKeyMap` already had literal
      `'foc.id'`/`'foc.iq'` string entries — but `TelemetryKey` itself had no
      named constants for them, and the real call site
      (`apps/dashboard/lib/main.dart`'s `_onPayload`) simply never copied
      `v.id`/`v.iq` into the ingest map, silently dropping two fully-decoded
      fields. Added `TelemetryKey.focId`/`focIq`, wired them into the ingest
      map, and seeded them into both mock preview telemetry stores (Studio's
      canvas and template previews) so they're bindable there too. Updated
      `pipeline_test.dart`'s "ingests all N keys" test (14 → 16) to cover them.
- [x] [P1] Per-widget size from document (via properties approach, no schema migration)
- [ ] [P2] Dark / light theme obeying widget background colors
- [x] [P2] Metric / imperial unit conversion (per-widget, not global) (2026-09-13):
      same work as Milestone 10's "Per-widget unit system" item — see that
      entry. Covers speed (`digitalspeed`) and temperature (`minigauge`).
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
- [x] [P1] **Rotation property/field in the inspector** (2026-09-13) —
      done; see `_PositionFields` in `studio_inspector.dart`.
- [x] [P1] Rotation handle on canvas (drag to rotate) (2026-09-13): a new
      `_DragSession.rotate` type in `editor_canvas.dart`, hit-tested via a
      handle drawn 24px above the shape's own local top-centre — computed by
      transforming that local point through the node's current matrix, so
      the handle stays attached to (and rotates with) an already-rotated
      shape rather than sitting on a static axis-aligned box. Pivots around
      the shape's true geometric centre (`MatrixUtils.transformPoint` of its
      local centre) rather than the numeric rotation field's top-left-origin
      pivot (`NodeTransforms.compose`'s `rotationZ` is anchored at the local
      origin) — a deliberate inconsistency between the two controls, since
      center-pivot is the expected feel for an interactive drag handle and
      changing the numeric field's pivot would alter every already-saved
      dashboard's rotation semantics. Scoped to single-selection only for
      now — the group-rotation pivot decision for multi-select is still
      open, deliberately deferred rather than guessed at. Widget tests in
      the `editor_canvas` package drive the actual gesture (not just the
      matrix math) and confirm multi-select correctly does NOT expose the
      handle. Anchor point for resize (separate from rotate) still open.
- [x] [P1] Bar properties: barRadius, showValue, gradient, gradientColor
      (2026-09-13) — see `bar_widget_test.dart`.
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
- [x] [P2] Golden-screenshot regression tests via `tools/dashboard_renderer`
      (2026-09-13) — found and fixed 2 real overflow bugs on first run
      (text, tripstats' Porsche-pod row). See
      `tools/dashboard_renderer/test/example_dashboards_golden_test.dart`.
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

- [ ] [BLOCKED] [P1] Android release build (APK signing) — needs a keystore
      and signing credentials only the project owner can provide; flagging
      rather than attempting a workaround (e.g. a throwaway debug-signed
      "release" build) since that would produce an artifact that looks
      shippable but isn't actually signed for a real release.
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

- [x] [P1] First-run onboarding (2026-09-13): the "build your first dashboard"
      guided flow is now split across two pieces rather than one big wizard —
      (1) Template mode is the default landing (previous item), which is
      itself a guided "pick a starter, see it live, tweak, save" path; (2) for
      the from-scratch path, added a one-time dismissible `_FirstDropHint`
      overlay ("Drag a widget from the palette to add it here") shown centred
      on Canvas mode only while the scene is empty and the hint has never
      been dismissed (`SettingsService.canvasHintDismissed`, persisted).
      Dismissed permanently on first successful drop, not just while widgets
      exist — deleting everything later doesn't bring it back. Chose this
      over expanding the static onboarding carousel (studio_onboarding.dart)
      because it's contextual — the hint appears exactly where and when the
      user needs it, on the actual canvas, rather than a wall of text shown
      once well before the canvas exists. Caught and fixed a real bug along
      the way: wrapping EditorCanvas in a Stack (to layer the hint) silently
      changed its constraints from tight to loose (Stack defaults to
      StackFit.loose), which collapsed the canvas's effective hit-test size
      and broke keyboard shortcuts/selection in tests without any visible
      symptom — fixed via `StackFit.expand`. Added widget tests for
      show/hide/permanent-dismissal and settings-service persistence.
- [x] [P1] Per-widget unit system (2026-09-13): added `TemperatureUnit`/`SpeedUnit`
      enums + `convertTemperature`/`convertSpeed` to `widgets_library/src/format.dart`
      (parse/suffix helpers included). Wired `sourceUnit`/`displayUnit` properties
      into `digitalspeed_widget.dart` as the v1 widget — opt-in, no `displayUnit`
      set means byte-identical old behaviour (raw value + literal `unit` string),
      so no existing dashboard changes look. Added manifest entries + inspector
      defaults + unit + widget tests (all green, no golden regressions). Extending
      `sourceUnit`/`displayUnit` to other speed/temp-bearing widgets (minigauge's
      temperature preset, gauge, bar) is the same pattern, left for a follow-up
      pass rather than doing all of them in one sweep.
- [x] [P1] Template gallery as default landing (2026-09-13): `editorModeProvider`
      now defaults to `EditorMode.template` instead of `canvas`. Also fixed two
      latent gaps this exposed: (1) the "Open dashboard" dialog never forced
      Canvas mode after loading a document, so opening a save while in
      Template mode would leave the gallery on screen over the loaded scene —
      now sets mode to canvas on open, same as "New dashboard" already did;
      (2) `_TemplatePreview`'s card thumbnails hardcoded every widget into a
      300×220 box regardless of its own declared width/height, which the
      Porsche trip-stats pod (designed for 480×480, with 70/50px fixed
      padding) overflowed by 114px — previously invisible because Template
      mode was never the boot screen in any test. Fixed to read
      `properties['width']`/`['height']` the same way the real Canvas editor
      does (`studio_canvas_area.dart`'s nodeWidth/nodeHeight). Updated 5 studio
      tests that assumed Canvas-mode boot to explicitly switch modes first;
      all pass, no golden regressions.
- [x] [P2] Contextual tooltips/help extended to canvas tools and palette
      (2026-09-13): canvas toolbar icons (grid/snap/orientation) already had
      `tooltip:` set via plain `IconButton`; the actual gap was the palette,
      which had exactly one tooltip in the whole file (the search-clear
      button) — the 22 widget-kind tiles and every preset under them had
      none, despite being the first thing a new user has to make sense of.
      Added `kindDescription(String kind)` to `widgets_library`'s
      `kind_icons.dart` (same single-source-of-truth pattern as `kindIcon`)
      — a one-line plain-language description per kind — and wired it into
      both the kind tile (icon + title) and each draggable preset row.
      Added a completeness test asserting every kind in `propertyManifest`
      has a real (non-fallback) description, so a newly-added widget kind
      can't silently ship without one.
- [x] [P2] Smart-default widget positioning when dropped on canvas (2026-09-13):
      dropping a widget onto a spot already covered by another now nudges it
      to the nearest clear spot (`_avoidOverlap` in `studio_canvas_area.dart`,
      an expanding-ring search using the same `transformedBounds` helper the
      layer panel's overlap-warning icon already relies on) instead of
      stacking them exactly on top of each other; falls back to the drop
      position unchanged if the canvas is too dense to find a clear spot
      nearby, since overlap is sometimes intentional (see `findOverlappingNodes`'s
      own doc comment) and this is a papercut fix, not a hard constraint.
      Caught a real bug in my own first pass: the search step was a fixed
      32px, shorter than most widgets' own footprint (300px+), so it could
      never actually search far enough to clear an overlap — fixed by
      scaling the step to the dropped widget's own size. Widget test added.
      Grid-snap (the other half of this line) not done — left as a smaller
      follow-up since overlap-avoidance was the actual pain point.
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
