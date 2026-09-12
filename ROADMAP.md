# Veschub Roadmap

Last updated: 2026-09-12

## Legend

- `[P0]` — Blocking / must-do-next
- `[P1]` — Important / next milestone
- `[P2]` — Nice to have / lower priority
- `[P3]` — Future / deferred
- `[SIDETRACKED]` — Intentionally paused; pick up later, not blocking anything below it

## Current priority order

Milestone numbers below are historical, not priority order. Right now:

1. **Milestone 5** — Studio Polish (manifest audit test, rotation, layers, units)
2. **Milestone 9** — AI Dashboard Assistant (Guidance mode, then Auto mode)
3. **Milestone 10** — Independent Creation & Ease of Use
4. Milestones 4, 6, 7 — as they come up
5. **Milestone 3 (Real Hardware)** — sidetracked, resume once 5/9/10 are solid

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
- [ ] [P0] Manifest-vs-renderer audit test: assert every `props[...]` a widget
      renderer reads has a matching `PropertyMeta` entry (prevents the
      text/chart drift class found during the AI-dashboards push)
- [ ] [P1] Rotation handle on canvas + rotation property/field in the inspector
      (parallel to `_PositionFields`), plus an anchor point for resize/rotate
- [ ] [P1] Bar properties: barRadius, showValue, gradient, gradientColor
- [ ] [P1] Multiple selection with group operations
- [x] [P2] Layer panel: reorder widgets by z-height, visibility toggle
- [ ] [P2] Layer panel: per-layer lock, matching the original z-height ask
- [ ] [P2] Cut / copy / paste between dashboards
- [ ] [P2] Keyboard shortcuts (delete, copy, undo, redo)
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
