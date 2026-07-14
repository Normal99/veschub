# Future Features

Work deferred from the phased plan to be implemented after the core phases are
complete. Each item carries its originating phase and a short scope note.

## Phase 8 — Navigation (Max-G3 features)

Origin: `veschub-rework.md` phase 8.

The `navigation` package exists as an empty stub. Full scope, to be implemented
later:

- **GPS widget** — current position + speed/heading readout, bound to `gps.*`
  telemetry keys.
- **Offline maps** — `flutter_map` + `latlong2`, offline tile caching for
  no-signal riding.
- **GPX import/export** — routes and recorded trips as GPX 1.1.
- **Route planning** — author/follow a route on the map.
- **Turn-by-turn** (explicitly "later" in the plan).
- **Trip recording + ride stats** — record a ride (timestamped positions +
  telemetry snapshots) and show distance/duration/avg-speed/elevation stats.

Suggested foundation when picked up: pure-Dart geo models (`GeoPoint`,
`Route`, `Trip`, `TripStats`), a hand-rolled GPX 1.1 codec (no extra dep), a
`TripRecorder` fed from `vesc_telemetry`'s `gps.*` keys, and a `MapWidget`
placeholder in `widgets_library` before pulling `flutter_map`.
