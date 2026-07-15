# Veschub

A Flutter-based **dashboard studio + runtime for VESC** (electric skateboard / EV)
controllers. Build dashboards visually in the **studio** app, then render them live in
the **dashboard** app against real VESC telemetry over BLE or USB-serial. Both apps
share the same packages, so what you author is exactly what renders.

> The legacy TypeScript/turbo repository is abandoned. This is a greenfield rewrite in
> Flutter/Dart, structured as a clean [Melos](https://melos.invertase.dev) monorepo.

---

## Table of contents

- [Features](#features)
- [Repository layout](#repository-layout)
- [Prerequisites](#prerequisites)
- [Getting started](#getting-started)
- [Running the apps](#running-the-apps)
- [Build, test & codegen commands](#build-test--codegen-commands)
- [Architecture overview](#architecture-overview)
- [The dashboard document format](#the-dashboard-document-format)
- [Capability levels & editor modes](#capability-levels--editor-modes)
- [Built-in widget kinds](#built-in-widget-kinds)
- [Telemetry keys](#telemetry-keys)
- [The VESC simulator](#the-vesc-simulator)
- [Settings & onboarding](#settings--onboarding)
- [Continuous integration](#continuous-integration)
- [Branching strategy](#branching-strategy)
- [Contributing](#contributing)
- [Roadmap / deferred work](#roadmap--deferred-work)

---

## Features

- **Hybrid editor** with three modes that scale with the user's comfort level:
  - **Template** — pick a starter dashboard and tweak safe knobs (colours, units, limits).
  - **Canvas** — drag-drop widgets onto a scene-graph canvas, edit transforms & bindings.
  - **Flow** — a node-graph dataflow editor for advanced reactive bindings (Expert).
- **Eight built-in widget kinds** — gauge, bar, text, status, chart, image, web, and a
  declarative `paint` DSL for custom drawing.
- **Versioned, migratable document format** — older dashboards upgrade automatically;
  newer builds reject (never silently corrupt) documents they don't understand.
- **Real hardware, real protocol** — a typed VESC COMM frame codec plus a transport
  abstraction over BLE, USB-serial, and an in-memory virtual transport for tests.
- **Shared runtime** — the same `dashboard_runtime` package evaluates bindings and
  repaints in both the studio preview and the live dashboard app.
- **Onboarding & settings** — first-run onboarding and a settings screen in both apps,
  backed by `shared_preferences`.

## Repository layout

```
veschub/
├── apps/
│   ├── studio/            # editor app (build dashboards) — desktop + tablet
│   └── dashboard/         # runtime app (render dashboards) — phone, Pi, desktop
├── packages/
│   ├── vesc_proto/        # VESC COMM frame codec (encode/decode, typed)
│   ├── vesc_transport/    # connection abstraction: BLE + USB-serial + virtual
│   ├── vesc_telemetry/    # typed value store + per-key streams
│   ├── dashboard_model/   # versioned, serializable dashboard document (freezed/json)
│   ├── dashboard_runtime/ # evaluates a model against telemetry → repaints
│   ├── dashboard_storage/ # drift (SQLite) persistence for dashboards
│   ├── widgets_library/   # built-in widgets: gauge, bar, chart, status, paint…
│   ├── editor_canvas/     # reusable scene-graph editor + commands
│   ├── node_graph/        # dataflow model for pro binding mode
│   ├── node_graph_editor/ # Flutter UI for the node-graph editor
│   ├── paint_dsl/         # declarative custom-paint DSL (serialisable ops)
│   ├── templates/         # built-in starter dashboard catalog
│   ├── settings/          # SettingsService (shared_preferences) + provider
│   ├── app_integration/   # launch apps / share / deep links
│   └── navigation/        # GPS, routes, GPX (stub — see roadmap)
├── tools/
│   └── vesc_sim/          # mock VESC speaking the protocol over virtual transport
├── .github/workflows/ci.yml
├── melos.yaml
├── analysis_options.yaml
├── AGENTS.md
└── FUTURE_FEATURES.md
```

## Prerequisites

- **Flutter** (stable channel) and **Dart >= 3.4** — https://docs.flutter.dev/get-started/install
- **[melos](https://melos.invertase.dev)** — install once:
  ```sh
  dart pub global activate melos
  ```
  Make sure melos is on your `PATH` (typically `~/.pub-cache/bin`).
- **Android SDK** (for the `dashboard` Android target). Run `flutter doctor` and resolve
  any issues before building for a device.

## Getting started

```sh
# 1. Install melos (once)
dart pub global activate melos

# 2. From the repo root, bootstrap all packages (resolves deps + pub get)
melos bootstrap

# 3. Generate code (freezed / json_serializable / drift)
melos run build_runner

# 4. Run an app (see "Running the apps" below)
flutter run --directory apps/dashboard
flutter run --directory apps/studio
```

> **After pulling changes** that touch models, re-run `melos bootstrap` and
> `melos run build_runner` to keep generated code in sync.

## Running the apps

Both apps accept the standard `flutter run` flags (`-d <device-id>`, `--release`, etc.).

```sh
# The runtime (renders dashboards against live telemetry)
flutter run --directory apps/dashboard

# The editor (build and edit dashboards)
flutter run --directory apps/studio

# The mock VESC simulator (emits telemetry at 10 Hz over a virtual transport)
dart run tools/vesc_sim/bin/vesc_sim.dart
```

The dashboard app ships a **bare viewer** wired to the virtual transport for
development, so you can see live telemetry without hardware during development.

## Build, test & codegen commands

These are the canonical commands used by CI and should be run after non-trivial changes:

```sh
melos run format          # dart format --set-exit-if-changed .
melos run analyze         # flutter analyze .
melos run test            # flutter test (every package with a test/ dir)
melos run test:unit       # same, excluding the two apps
melos run build_runner    # regenerate freezed/json/drift code
melos run build_runner:watch  # regenerate on file change
```

### Package-scoped (faster) variants

```sh
melos run test --scope=vesc_proto
melos exec --scope=vesc_proto -- flutter test
```

> **Note:** `melos run` can prompt interactively in a non-TTY shell. In scripts or CI,
> prefer `melos exec --scope=<pkg> -- <command>`.

### Pure-Dart packages

A few packages (`vesc_proto`, `dashboard_model`, `paint_dsl`, `navigation`, …) are
pure-Dart and can be tested with `dart test`:

```sh
dart test --directory packages/vesc_proto
```

## Architecture overview

The data flows in one direction:

```
 VESC hardware ──vesc_transport──▶ vesc_telemetry (typed store + streams)
                                         │
   dashboard_model (document JSON)       │
         │                               │
         ▼                               │
   dashboard_runtime ◀────bindings───────┘
         │  resolves each widget's properties to live values
         ▼
   widgets_library (renders gauge/bar/chart/…)
         │
   ├── apps/studio     (editor + live preview)
   └── apps/dashboard  (full-screen runtime)
```

- **`vesc_proto`** encodes/decodes the binary VESC COMM frames into typed
  `TelemetryValues`.
- **`vesc_transport`** abstracts the wire (BLE / USB-serial / in-memory virtual) behind
  a single `Connection` interface.
- **`vesc_telemetry`** holds the latest decoded values per canonical key and exposes
  per-key streams; the runtime subscribes to these to know when to repaint.
- **`dashboard_model`** is the versioned, JSON-serializable document authored by the
  studio and consumed by the runtime.
- **`dashboard_runtime`** resolves each widget's `Binding`s against the telemetry store
  and triggers repaints (wrapped in `RepaintBoundary` so only dirty widgets repaint).
- **`widgets_library`** renders each widget kind from its resolved properties, shared by
  both the studio preview and the dashboard app.
- **`editor_canvas`** is the reusable scene-graph editor (transforms, selection, undo
  via commands) that powers studio's Canvas mode.
- **`node_graph` + `node_graph_editor`** power the Flow mode dataflow bindings.
- **`paint_dsl`** is a small declarative language of drawing ops rendered by the `paint`
  widget kind; numeric coordinates can reference telemetry values for live painting.
- **`dashboard_storage`** persists dashboards to a local drift (SQLite) database.
- **`templates`** holds the built-in starter dashboard catalog.
- **`settings`** provides a `SettingsService` (over `shared_preferences`) and a shared
  Riverpod provider consumed by both apps.

## The dashboard document format

A `DashboardDocument` is the unit authored in the studio and rendered by the runtime.
It is versioned (`kCurrentDocumentVersion`) and migrated by `DashboardMigrator` before
decode, so older documents upgrade automatically and newer builds reject documents they
don't understand (rather than silently corrupting them).

Each `WidgetInstance` carries:

- `id`, `kind` (e.g. `'gauge'`),
- a 2D affine `transform` (6-element row-major matrix) rather than x/y/w/h — matching
  the scene-graph editor,
- `z` ordering,
- a `properties` map of `String → Binding`,
- a minimum `CapabilityLevel`.

A `Binding` is a discriminated union:

- **`literal`** — a constant value baked into the document,
- **`telemetry`** — resolved from the telemetry store by canonical key,
- **`graph`** — resolved by a node-graph dataflow (Expert mode only).

Example (abbreviated) document JSON:

```json
{
  "version": 2,
  "name": "Minimal",
  "description": "One large gauge — speed/RPM at a glance.",
  "canvas": { "width": 800, "height": 480 },
  "background": 4278190080,
  "accent": 4292362720,
  "widgets": [
    {
      "id": "rpm",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 250, 130],
      "properties": {
        "value": { "type": "telemetry", "key": "erpm" },
        "min":   { "type": "literal", "value": 0 },
        "max":   { "type": "literal", "value": 100000 }
      }
    }
  ]
}
```

When you change the on-disk shape of a document, **bump `kCurrentDocumentVersion`** and
add a migration step in `packages/dashboard_model/lib/src/migrator.dart`.

## Capability levels & editor modes

Every widget kind and every inspector property declares a `CapabilityLevel`, and the
studio gates visibility accordingly. This is the "hybrid editor":

| Level     | Editor mode  | Audience                          |
|-----------|--------------|-----------------------------------|
| `basic`   | **Template** | First-time users — safe knobs only|
| `advanced`| **Canvas**   | Power users — full layout/binding |
| `expert`  | **Flow**     | Pros — node graphs + paint DSL    |

- `CapabilityLevel.includes(other)` returns true when `other <= this`.
- The studio inspector consults `PropertyMeta` (in `widgets_library`) to decide which
  properties to reveal at the user's chosen level.

## Built-in widget kinds

Registered in `packages/widgets_library/lib/widgets_library.dart`:

| Kind     | Level     | Description                                             |
|----------|-----------|---------------------------------------------------------|
| `text`   | basic     | A labelled text readout.                                |
| `bar`    | basic     | A horizontal/vertical progress bar.                     |
| `gauge`  | basic     | An arc gauge (speed/RPM/duty).                          |
| `status` | basic     | Fault / status indicator from the `fault` telemetry key.|
| `image`  | basic     | A static or asset image.                                |
| `chart`  | advanced  | A rolling time-series chart.                            |
| `web`    | advanced  | An embedded web view (platform-adaptive).               |
| `paint`  | expert    | Runs a `PaintProgram` (from `paint_dsl`) on a `Canvas`. |

## Telemetry keys

Canonical, dot-delimited keys defined in `packages/vesc_telemetry/lib/src/telemetry_key.dart`.
Widgets bind properties to these; the runtime re-evaluates a binding when its key changes.

- `erpm`, `duty`
- `current.motor`, `current.input`
- `v_in`
- `temp.motor`, `temp.mosfet`
- `amp_hours.charged`, `amp_hours.discharged`, `watt_hours.charged`, `watt_hours.discharged`
- `tachometer`, `tachometer_abs`
- `fault`
- `gps.lat`, `gps.lon`, `gps.speed`, `gps.heading` (populated from a GPS source, not the
  base VESC values packet — see roadmap)

## The VESC simulator

`tools/vesc_sim` is a mock VESC that speaks the real protocol over an in-memory virtual
transport, emitting telemetry at 10 Hz. Use it to develop and demo without hardware:

```sh
dart run tools/vesc_sim/bin/vesc_sim.dart
```

It prints decoded telemetry to stdout as a smoke check and runs for 30 seconds by
default. The dashboard app's bare viewer is wired to the same virtual transport for
development.

## Settings & onboarding

- **`packages/settings`** exposes `SettingsService` (a `ChangeNotifier` over
  `shared_preferences`) and a shared `settingsServiceProvider` (Riverpod
  `ChangeNotifierProvider`). Both apps import the single provider definition from
  `package:settings/settings.dart`.
- Both apps show a **first-run onboarding** flow and a **settings screen**. Onboarding
  state is persisted; once completed, the app routes straight to the editor/runtime.

## Continuous integration

`.github/workflows/ci.yml` runs on every push/PR to `main`:

1. `melos bootstrap`
2. `melos run format` — fail if formatting would change
3. `melos run analyze`
4. `melos run build_runner`
5. `melos run test`

Keep `main` green — all of these must pass before merge.

## Branching strategy

- `main` — always green; protected. Releases are tagged from `main`.
- `feature/<scope>-<short-desc>` — e.g. `feature/proto-codec`, `feature/dashboard-viewer`.
- `fix/<short-desc>` — bug fixes.
- Trunk-based: small PRs, fast rebase/merge to `main`. Keep branches short-lived.

## Contributing

1. Branch from `main` using the naming above.
2. Make your changes; add/extend tests under each package's `test/` directory.
3. Regenerate code if you touched models: `melos run build_runner`.
4. Run the full gate locally before pushing:
   ```sh
   melos run format && melos run analyze && melos run test
   ```
5. Open a PR against `main`; CI must pass before merge.

### Conventions

- Every package uses `flutter_lints` via the root `analysis_options.yaml`.
- Generated files (`*.freezed.dart`, `*.g.dart`, `*.drift.dart`) are checked in; never
  hand-edit them.
- Prefer absolute `package:` imports over relative ones.
- When adding a widget kind: register it in `widgets_library.dart`, add its
  `PropertyMeta` entries in `property_manifest.dart`, and add tests.

## Roadmap / deferred work

Deferred items are tracked in [`FUTURE_FEATURES.md`](./FUTURE_FEATURES.md). The notable
one is **Phase 8 — Navigation**: GPS widget, offline maps (`flutter_map`), GPX
import/export, route planning, turn-by-turn, and trip recording. The `navigation`
package exists as an empty stub awaiting this work.

## License

TBD.
