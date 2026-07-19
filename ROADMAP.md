# Veschub Roadmap

Last updated: 2026-07-19

## Legend

- `[P0]` — Blocking / must-do-next
- `[P1]` — Important / next milestone
- `[P2]` — Nice to have / lower priority
- `[P3]` — Future / deferred

---

## Milestone 1: Studio MVP ✅

- [x] Drag-drop widgets onto canvas
- [x] Property inspector with literal / telemetry / graph bindings
- [x] Editor canvas: move, resize, snap, undo/redo
- [x] Save / load dashboards (SQLite)
- [x] Template gallery with live previews
- [x] Capability-level gating (Basic / Advanced / Expert)
- [x] Flow mode: node-graph editor with DragTarget
- [x] Paint DSL: declarative custom-paint widget
- [x] 8 widget kinds: gauge, bar, text, status, chart, image, web, paint

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

## Milestone 3: Real Hardware 🚧

- [ ] [P0] BLE transport adapter (`packages/vesc_transport`)
- [ ] [P0] USB-serial transport adapter
- [ ] [P1] Transport auto-detection (scan + connect flow)
- [ ] [P1] Manual connect / disconnect UI in dashboard
- [ ] [P2] Transport status indicator with error recovery
- [ ] [P2] Connection timeout + retry logic

## Milestone 4: Dashboard Viewer Polish 🚧

- [ ] [P1] Telemetry ingestion for remaining 4 keys (foc.id, foc.iq)
- [ ] [P1] Per-widget size from document (schema v3 migration)
- [ ] [P2] Dark / light theme obeying widget background colors
- [ ] [P2] Metric / imperial unit conversion (per-widget, not global)
- [ ] [P3] Dashboard app display modes: fullscreen, splitscreen, Pi-optimized

## Milestone 5: Studio Polish 🚧

- [ ] [P0] Grid layout + snap (toggleable grid overlay, snap-to-grid)
- [ ] [P0] Canvas custom width/height input (replace HD/FHD/QHD presets)
- [ ] [P0] Widgets opaque by default with configurable background color
- [ ] [P1] Widget borders / shadows (property manifest extension)
- [ ] [P1] More gauge properties: tick count, sweep angle, needle style, color stops
- [ ] [P1] More font properties: fontWeight, fontFamily, letterSpacing, textAlign
- [ ] [P1] Multiple selection with group operations
- [ ] [P2] Layer panel: reorder widgets by z-height, visibility toggle
- [ ] [P2] Cut / copy / paste between dashboards
- [ ] [P2] Keyboard shortcuts (delete, copy, undo, redo)
- [ ] [P3] Dashboard description rich text / markdown

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
