# Veschub

Veschub v2 — a Flutter-based dashboard studio + runtime for VESC (electric skateboard / EV)
controllers. Built from scratch as a clean Melos monorepo. The **studio** app authors
dashboards; the **dashboard** app renders them live against VESC telemetry over BLE or
USB-serial. Both apps share the same packages so what you author is exactly what renders.

> **Note:** The legacy TypeScript/turbo repository at the old `veschub` is abandoned.
> Nothing is reused. This is a greenfield rewrite in Flutter/Dart.

## Repository layout

```
veschub/
├── apps/
│   ├── studio/            # editor app (build dashboards) — desktop + tablet
│   └── dashboard/         # runtime app (render dashboards) — phone, Pi, desktop
├── packages/
│   ├── vesc_proto/        # VESC COMM frame codec (encode/decode, typed)
│   ├── vesc_transport/    # connection abstraction: BLE + USB-serial + virtual
│   ├── vesc_telemetry/    # typed value store + streams
│   ├── dashboard_model/   # serializable dashboard document (freezed/json)
│   ├── dashboard_runtime/ # evaluates a model against telemetry → repaints
│   ├── widgets_library/   # built-in widgets: gauge, bar, chart, map, status…
│   ├── editor_canvas/     # reusable scene-graph editor
│   ├── node_graph/        # dataflow editor for pro binding mode
│   └── navigation/        # GPS, routes, GPX, offline maps, trips
├── tools/
│   └── vesc_sim/          # mock VESC speaking the protocol over virtual transport
└── melos.yaml
```

## Prerequisites

- Flutter (stable) and Dart >= 3.4 — https://docs.flutter.dev/get-started/install
- [`melos`](https://melos.invertase.dev): `dart pub global activate melos`
- Android SDK (for the `dashboard` Android target) — `flutter doctor` should be green.

## Getting started

```sh
# 1. Install melos (once)
dart pub global activate melos

# 2. From the repo root, bootstrap all packages (resolves deps + pub get)
melos bootstrap

# 3. Generate code (freezed / json_serializable / drift)
melos run build_runner

# 4. Run the apps
flutter run -p <device-id> --directory apps/dashboard
flutter run -p <device-id> --directory apps/studio

# 5. Run the mock VESC simulator
dart run tools/vesc_sim/bin/vesc_sim.dart
```

## Build & test commands

These are the canonical commands used by CI and by all contributing agents. They MUST be
run after non-trivial changes:

```sh
melos run format      # dart format --set-exit-if-changed .
melos run analyze     # flutter analyze .
melos run test        # flutter test (in every package that has a test/ dir)
```

Package-scoped (faster) variants:

```sh
melos run test --scope=vesc_proto
melos exec --scope=vesc_proto -- flutter test
```

Regenerate generated code after touching models:

```sh
melos run build_runner
```

## Branching strategy

- `main` — always green; protected. Releases are tagged from `main`.
- `feature/<scope>-<short-desc>` — e.g. `feature/proto-codec`, `feature/dashboard-viewer`.
- `fix/<short-desc>` — bug fixes.
- Trunk-based: small PRs, fast rebase/merge to `main`. Keep branches short-lived.

## Capability levels

Every widget and feature declares a level — **Basic / Advanced / Expert** — and the studio
UI gates visibility accordingly. See `packages/dashboard_model` for the level enum and the
hybrid editor modes (Template / Canvas / Flow).

## License

TBD.
