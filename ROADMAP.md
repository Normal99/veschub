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
  - `warnings` shows icons with no text labels (low clarity — a beginner
        may not know what the icons mean without hovering/guessing);
        `power_flow` is visually very thin/minimal compared to its
        neighbors. Neither is broken, just weak.
        **Both fixed 2026-09-13**: `warnings` got a new `showLabels`
        property (default true, same pattern as appgrid/car_viz) printing
        each warning's own message under its icon instead of only on
        hover (tooltip stays too, for the full message). `power_flow` got
        a thicker default bar (4px → 8px), a visible track border at 0%
        fill (same fix `bar_widget.dart` already had), pill-shaped
        corners, and a bolt/charging icon so direction reads at a glance
        instead of only via which side the bar fills from. Neither widget
        had a dedicated test before this — added one file each. Verified
        visually via `tools/dashboard_renderer` with real fonts loaded
        (golden tests render text as blank boxes) by rendering the full
        Tesla template from the `templates` package directly, since none
        of the 9 static `examples/*.veschub.json` happen to use
        `power_flow`.
- [x] **FIXED**: `power_widget.dart`'s bar row overflowed by exactly 2px at
      the default drop size — found by actually dropping a "Power Meter"
      preset in the live running app (not caught by any existing automated
      test) and noticing Flutter's debug overflow banner. Root cause: the
      bar-width formula sized each of the 20 bars assuming 19 gaps between
      them, but every bar (including the last) got a right `margin`, adding
      a 20th gap's worth of width — an off-by-one that overflows by exactly
      `gap` (2.0px) regardless of container width. Fixed by omitting the
      margin on the final bar; added `power_widget_test.dart` (verified it
      actually fails without the fix by reverting it and re-running).
- [x] [P2] **Genuinely minimal starter widgets** (2026-09-13): added a
      `Minimal` preset each to the `text` and `bar` palette entries in
      `studio_palette.dart` — bare number (transparent background, no
      label, no card chrome) and an undecorated thin fill bar (zero radius,
      zero padding), alongside the existing styled/car-brand presets rather
      than replacing them. `gauge` already had a comparable `Minimal Arc`
      preset from before this session.
- [x] [P1] **Palette presets: no more default background boxes, muted
      colours don't pop** (2026-09-13): user feedback was blunt — "none of
      these widgets should have a background by default", and defaults
      "look muted and don't pop how you expect" for a dashboard. Audited
      every preset in `apps/studio/lib/editor/studio_palette.dart`'s
      `_templates` map (all 16 kinds that actually have presets) against
      `resolveBoxDecoration` in `packages/widgets_library/lib/src/
      cosmetic_helpers.dart` (confirmed default `backgroundColor` is
      `0x00000000`, default `borderRadius`/`borderWidth` are `0`).
  - Stripped `backgroundColor`/`borderRadius`/`borderWidth`/`borderColor`
        from 31 presets across `gauge` (BMW Amber, Audi Sport, Porsche
        Green), `bar` (Horizontal, Vertical), `text` (Sans, Compact),
        `chart` (Line Chart, Area Chart), `digitalspeed` (all three),
        `music` (Player, Mini), `tripstats` (both), `power` (both —
        this is the "Power Meter" the user called out directly),
        `warnings` (Warning Icons), `minigauge` (all three), `appgrid`
        (both), `statusbar` (Top Bar), `climate` (both), `car_viz`
        (Lane Assist), `map` (Navigation), `battery_range`. Left
        `bar > Wide Card` (explicit card look, name says so) and the
        `Minimal` presets (already correct) untouched.
  - **Judgment call**: checked each kind's renderer in
        `packages/widgets_library/lib/widgets/` before deleting
        `borderRadius` blindly — `bar_widget.dart` reuses the same
        `borderRadius` prop to shape the track/fill pill itself (not
        just an outer box), so bar presets keep `borderRadius` and only
        lose `backgroundColor`. `image_widget.dart` and `web_widget.dart`
        use `borderRadius` to round the actual image/webview content
        (a legitimate "framed" look, not a pointless box), so `image`
        and `web` presets were left alone entirely.
  - **Judgment call**: kept `status > Pill`'s background — read
        `status_widget.dart` and its own doc comment calls it "a coloured
        pill + label... top-of-dashboard health indicator"; the widget
        always draws a severity-coloured border regardless of props, so
        the pill/badge look is baked into the widget's own design, not a
        removable decorative box. `status > Inline` (already transparent)
        is the clean alternative for anyone who doesn't want that.
  - Added `'fontWeight': L('bold')` to primary-value props on presets
        whose renderer hardcodes a thin default weight and the preset
        didn't already override it: `power` (both, default `w300`),
        `climate` (both, default `w300`), `digitalspeed` Compact/With Sub
        (default `w200`). Left `digitalspeed > Tesla Style`'s deliberate
        `w200` alone — that thin weight is the point of the preset name.
        Most other kinds' primary readouts already hardcode `w500`–`w700`
        in their renderers regardless of props, so no change was needed
        there; likewise most primary `color` values were already vivid
        (saturated green/orange/red/cyan) — the "muted" complaint turned
        out to be almost entirely the dark navy/black background boxes
        (`0xFF111122`, `0xFF0D0D1A`, `0xFF1A1A2E`, etc.) rather than the
        foreground colours themselves; removing those boxes is most of
        the "pop" fix.
  - `power_flow`'s one preset (`kW Bar`) and `gear_selector`'s one preset
        (`PRND`) already had `backgroundColor: 0x00000000` — no change
        needed, confirming these two were already compliant.
  - Verified: `flutter analyze`/`dart format` clean on the changed file;
        full `flutter test` in `apps/studio` (33 tests), `packages/
        widgets_library` (125 tests), and `tools/dashboard_renderer`
        (10 tests) all pass with zero golden diffs — the golden tests
        that drag a "Speedometer" preset onto the canvas were unaffected
        because that preset (built via the `_dial()` helper) already had
        a transparent background and wasn't touched.
- [x] [P2] **"We don't need a Power meter, we need a meter + text" — a
      primitive-based alternative** (2026-09-13): the user's underlying
      complaint about the `power` kind wasn't really about its background
      (already fixed above) but about it being a single-purpose, non-
      decomposable composite widget when the same "wattage at a glance" job
      should be buildable from general-purpose primitives. Deleting the
      `power` kind/renderer was explicitly out of scope (breaking change for
      any saved dashboard already using it, and the user said "presets do
      have their place... don't disregard them" — not a mandate to remove
      anything). Instead added a `Power` preset to `minigauge` (bound to the
      same `power` telemetry key, reusing its existing `icon: 'power'` →
      `Icons.bolt` mapping) so the primitive path is now equally one drag
      away in the palette, not just theoretically possible. A plain `text`
      widget bound to `power` already covered the "just the reading" case.
- [x] [P1] **Widget font system — no custom font existed at all** (2026-09-13):
      "the widget font system is a little scuffed" turned out to be literal —
      `grep -r "fonts:" apps/*/pubspec.yaml` and a search for `.ttf`/`.otf`
      anywhere in the repo both came back empty. Every widget rendered in
      whatever generic system font the host platform happened to have
      (Roboto on Linux/Android), which reads as plain/un-dashboard-like next
      to real digital-cluster typography. Added Rajdhani (SIL OFL 1.1 — see
      `packages/widgets_library/lib/assets/fonts/OFL.txt`; weights 300–700)
      as a package font declared once in `packages/widgets_library/pubspec.yaml`
      and exposed as `kDashboardFontFamily` in `packages/widgets_library/lib/
      src/theme.dart`, so every app that depends on `widgets_library` gets it
      automatically (Flutter's package-font mechanism) rather than needing
      the font files duplicated into each app.
  - Applied via `ThemeData(fontFamily: kDashboardFontFamily)` in
        `apps/dashboard` (both light/dark themes) and `tools/dashboard_renderer`
        (its golden-test rendering tool) — these two ARE the widget content,
        so app-wide is correct there.
  - Deliberately did NOT set it app-wide in `apps/studio` — Studio's own
        chrome (menus, inspector, toolbar labels) should stay in a normal
        legible UI font for productivity work; only the *previewed dashboard
        content* should show the real font, so what's edited visually matches
        what actually renders. Wrapped just the Canvas editor's widget-render
        area (`studio_canvas_area.dart`) and the Template gallery's preview
        thumbnails (`template_mode.dart`) in a local
        `DefaultTextStyle.merge(style: TextStyle(fontFamily: kDashboardFontFamily))`
        instead.
  - No widget file hardcodes its own `fontFamily` (confirmed via grep — the
        one property-driven exception, `gauge_widget.dart`'s needle-label
        painter, only sets it when the user explicitly configures a
        `fontFamily` property), so every `Text` with an unset `fontFamily`
        correctly inherits the ambient theme's font through normal
        `DefaultTextStyle` merging — no per-widget-file changes needed.
  - **Verification note**: `flutter test` golden-file comparisons across all
        three apps show **zero diff** with this change, which is expected,
        not a sign the wiring is broken — Flutter's default test binding
        does not load custom package fonts into golden renders regardless of
        `ThemeData`, a known framework limitation. Confirmed the font is
        actually applied by rebuilding the real Linux binary and visually
        inspecting a live-launched window instead of trusting golden tests
        for this specific check.
- [x] [P1] **Font selection in the inspector was broken — literally a raw
      integer** (2026-09-13): user feedback — "you can't select fonts, they
      are just an integer... it should be a dropdown with search, something
      most programs use." Confirmed exactly right: `_defaultBinding` in
      `studio_inspector.dart` had no case for `fontFamily` at all, so it fell
      through to the generic numeric fallback and defaulted to the literal
      **integer `0`** — a user's first encounter with the property was an
      unlabelled "0" in a plain text field. `fontWeight` was at least a valid
      string (`'bold'`) but was still a raw free-text field with zero
      discoverability of the 9 accepted values.
  - Added `packages/widgets_library/lib/src/font_catalog.dart`:
        `kFontChoices` (4 entries: Default + the 3 bundled fonts) and
        `kFontWeightChoices` (all 9 accepted weight strings, human-readable
        labels like "Semi Bold (600)").
  - Bundled two more fonts alongside Rajdhani — Orbitron (geometric sci-fi
        display, for a HUD look) and Share Tech Mono (monospaced
        terminal/telemetry look) — both SIL OFL 1.1, same
        `packages/widgets_library/<Family>` reference convention. A picker
        with only one real, non-default choice would have been a thin
        payoff for the UI work; three gives an actual style decision.
  - Replaced the raw-text-field dispatch for these two specific property
        keys with `_FontFamilyEditor`/`_FontWeightEditor` in
        `studio_inspector.dart`, both built on Flutter's stock
        `Autocomplete` widget (type to filter, pick from a dropdown) rather
        than a bespoke combobox — matches "something most programs use"
        without reinventing it. Fixed `_defaultBinding`'s `fontWeight`
        default to the canonical `'w700'` (was the `'bold'` alias) so the
        picker's options — which use canonical `w100`..`w900` forms — can
        actually match and highlight the current value; added an explicit
        `fontFamily` case defaulting to `''` ("Default"/inherit theme font)
        instead of falling into the broken integer fallback.
  - Real bug hit while writing the end-to-end test: `Autocomplete` only
        reads its `initialValue` once per Element, so an external change to
        the underlying property (undo/redo, switching selection) wouldn't
        resync the field's displayed text — the same class of problem
        `_LiteralEditor` already solves via a manual `didUpdateWidget`
        resync. Fixed by keying each picker on the current value
        (`key: ValueKey(value)`), forcing Flutter to recreate — and
        therefore re-read `initialValue` on — a genuine external change.
  - `apps/studio/test/font_picker_test.dart`: drives the real Studio UI
        (drop a gauge, expand "Fonts & Colors", search, select, verify the
        gauge's actual rendered `TextStyle` picked up the new
        `fontFamily`/`fontWeight`) rather than testing the picker in
        isolation. Along the way, found that `tester.drag(finder, offset)`
        picking a finder's geometric centre as the drag's start point can
        silently land on an interactive descendant (here, a text field)
        that doesn't bubble the gesture to an ancestor `Scrollable` —
        `tester.dragFrom` with an explicit corner-inset point was needed to
        reliably scroll the properties panel to a collapsed, off-screen
        category. Verified: `flutter analyze`/`dart format` clean, full
        `flutter test` in `apps/studio` (34 tests), `packages/
        widgets_library` (127 tests), and `tools/dashboard_renderer`
        (10 tests) all pass.

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

## Font system pass (2026-09-13)

User feedback: the car-brand templates aren't accurate to source material
in fonts, and "there is only a default font and only Bold" — investigated
before fixing anything, per the guiding principle above.

- [x] **FIXED — two real property bypasses** found via investigation
      (`applyTextStyle` itself correctly merges `fontFamily`/`fontWeight`
      symmetrically — the gap was upstream): `minigauge_widget.dart`'s
      vertical-bar style variant hardcoded `FontWeight.bold` via a raw
      `TextStyle` for both its label and main value, ignoring both
      properties entirely regardless of what the inspector was set to;
      `gauge_widget.dart`'s `_GaugePainter` threaded a `fontFamily` field
      through to itself but never read it when painting tick labels, so a
      chosen font never reached the small numeric labels on the arc (the
      big center readout was already correct). Root cause of "only
      Default/Bold": no template or palette preset ever set `fontFamily`
      (all default to the shared Rajdhani), and most palette presets
      default `fontWeight` to `'bold'`.
- [x] **Distinct font per car-brand template** (2026-09-13): bundled 8 more
      SIL OFL 1.1 fonts (Titillium Web, Barlow Condensed, Inter, Outfit,
      Roboto, Manrope, Exo 2, Sora) alongside the existing Rajdhani/
      Orbitron/Share Tech Mono, and gave each of the 9 templates its own
      `fontFamily` (previously all 9 shared Rajdhani, only weight/
      letterSpacing differed per the earlier "Template typographic
      identity" pass): tesla-model3→Inter, porsche-taycan→Outfit,
      bmw-classic→Titillium Web, audi-virtual-cockpit→Barlow Condensed,
      vesc-mobile→Rajdhani (explicit), android-auto→Roboto (the real one —
      Android Auto genuinely ships Roboto), carplay→Manrope, ford-digital→
      Exo 2, vw-digital→Sora. None of the others are the manufacturer's
      actual proprietary typeface (Tesla's Gotham, BMW Type, Audi Type,
      Porsche Next, Apple SF Pro aren't freely licensable) — picked as free
      stand-ins with a comparable feel, a judgment call per user direction
      to just pick and go. Titillium Web/Barlow Condensed ship real static
      weight files; the other six only exist as a single variable-font file
      upstream, bundled as one asset like the existing single-weight Share
      Tech Mono — their shape still differs correctly per brand, only their
      weight-picker range is limited. Verified by rendering 3 of the 9
      templates through `tools/dashboard_renderer` at full resolution (not
      just the small gallery thumbnails) to visually confirm each font is
      genuinely distinct, including gauge tick labels (confirming the bug
      fix above).
- [x] **Importable custom fonts** (2026-09-13): a "Custom Fonts" section in
      Studio Settings — import a `.ttf`/`.otf` via the same `FilePicker`
      pattern already used for dashboard/flow-graph JSON import, copy it
      into the app's own support directory, register immediately via
      `FontLoader` (usable without restarting), persist the family-name/
      file-path reference. Shows up alongside bundled fonts in any
      dashboard's font picker (`fontChoicesProvider` merges `kFontChoices`
      with the persisted list reactively). `CustomFontEntry`/
      `registerCustomFont`/`registerAllCustomFonts` live in
      `packages/settings` (not studio-only) since the dashboard viewer app
      needs to register the same fonts at its own startup to render a
      dashboard with the fonts it was built with — only the import UI
      itself is studio-specific. **Known limitation**: only works when both
      apps run on the same machine/filesystem (this project's current
      desktop-first setup) — true portability across separately-sandboxed
      installs would need embedding the font bytes in the exported
      `.veschub.json` itself, a bigger follow-up, not attempted. Verified
      end-to-end on the real running app: imported a real `.ttf` via the
      actual OS file picker, confirmed it persisted to disk, listed in
      Settings, applied via the Canvas font picker, and removed cleanly
      (including its file).
- [x] **FIXED — the actual root cause of "only Default/Bold"** (2026-09-13):
      user pushback on the above — "It needs to have fonts per widget as
      always... the only font family I can choose is Default" — led to
      reproducing it live rather than assuming the per-template pass was
      the issue. Real bug, more severe than anything above: `Autocomplete`
      pre-fills the field with the current selection's label and filters
      options by whatever text is already in the field, so opening either
      picker without clearing it first only ever matched itself ("Default"
      only matches "Default", "Bold (700)" only matches "Bold (700)") —
      every other choice looked like it didn't exist unless you already
      knew to clear the field and retype. Font selection was per-widget the
      whole time (each widget instance already has its own `fontFamily`
      property, template or not) — it just looked broken because the
      picker itself couldn't be browsed. Fixed by clearing the field on
      focus (shows the full list immediately, standard combobox behaviour)
      and restoring the label on blur if nothing was picked, in both
      `_FontFamilyEditor` and `_FontWeightEditor`. Added regression tests
      for the exact broken interaction (tap with no typing → must show
      multiple choices). Reproduced live on the running app before fixing,
      confirmed fixed after.

## Property inspector picker pass (2026-09-13)

User feedback: "multiple issues in the property tab... unrecognizable
suffixes... instead of options that are choosable" and a request for
Text/Gauge's "choose what value to display" to be easier — from a list or
a custom VESC variable.

- [x] **Real pickers for fixed-vocabulary string properties**: `PropertyMeta`
      gained an `options: List<EnumOption>?` field; a new generic
      `_EnumEditor` (same Autocomplete + clear-on-focus pattern as the font
      pickers above) renders whenever declared, replacing a raw text field
      that gave zero indication of valid values. Wired up for
      `gauge.needleStyle`, `bar`/`minigauge.orientation`, `minigauge.style`,
      `minigauge.icon`, `climate.mode`, `map.mapStyle`, and the speed/
      temperature `sourceUnit`/`displayUnit` pairs on `digitalspeed`/
      `minigauge`. `_defaultBinding`'s fallback for any options-bearing
      property is now its first declared option (a real value), not the
      numeric literal `0` it fell through to before — that literal-`0`
      fallback was itself a real, separate bug for any string-enum property
      with no explicit default (`style`, `icon`, `mapStyle`, `mode` all had
      none).
  - Caught a real, related bug while testing: the shared `_dial()` gauge
        preset helper (backing "Speedometer" and others) and the Tesla
        template both baked in `needleStyle: 'arc'` — not a value the gauge
        renderer recognises at all (only `'needle'` draws anything; every
        other string, 'arc' included, happened to produce "no needle" by
        accident, which is exactly why it went unnoticed). Fixed to the new
        canonical `'none'` value both places.
- [x] **Friendly telemetry key names + unified picker**: the "choose what
      value to display" binding editor now shows human-readable names
      ("Motor Speed (ERPM)") instead of only the raw VESC field name
      (`erpm`) via a new `telemetryKeyLabel()` in `packages/vesc_telemetry`.
      Rewrote `_TelemetryEditor` from a filter-box + `DropdownButton` +
      separate "Manual" mode toggle into one unified Autocomplete field —
      pick from the list, or type any custom key (a VESC LispBM variable,
      etc.) and press Enter, no mode switch needed. This directly answers
      "choose from a list or a custom variable from VESC": that capability
      already existed, it just wasn't discoverable/friendly; the mechanism
      itself didn't need to change.
  - Verified live on the running app (not just tests): reproduced the
        needleStyle bug's raw "arc" value on screen before fixing it,
        confirmed pickers show the full option list with real labels after.
- [x] **FIXED — "I'm not seeing anywhere to set the values at all"**: root
      cause was that the inspector auto-expands only the first non-empty
      `PropertyCategory`, and `PropertyCategory.values` declared Visuals
      before Data Bindings — so for nearly every kind (label/unit/icon/etc
      are Visuals, present almost everywhere), Visuals won that slot and
      Data Bindings (where the actual value/telemetry binding lives) stayed
      collapsed, easy to miss on first encounter. Reordered so Data
      Bindings is declared first: what value a widget actually shows is now
      what you see immediately after dropping it, ahead of cosmetic
      categories. Also raised in the same message: a request to de-
      emphasize presets in favor of building from primitives (Text/Gauge/
      Meter) with free binding to telemetry/formula/custom variables —
      investigated and confirmed that capability already exists uniformly
      for every property regardless of which preset (or none) a widget was
      dropped from; presets only pre-fill starting values, they don't
      restrict what you can rebind afterward. Gauge/Bar/Text already have a
      "Minimal" blank-ish starter preset from an earlier pass. Flagged back
      to the user rather than assumed: most of the "preset-locked" feeling
      may simply have been this same discoverability bug, now fixed.
- [x] **FIXED — the actual bug, found by pushing further** (2026-09-14):
      the previous entry's "discoverability bug, now fixed" claim turned
      out to be incomplete — user reported, forcefully and specifically,
      that a fresh Text widget still had no way to set its value.
      Reproduced live end-to-end rather than trusting the earlier fix: root
      cause was that 57 of 76 Data Bindings properties across the *entire*
      widget library — including `value` on nearly every kind — required
      `CapabilityLevel.advanced`, invisible on the `basic` level every
      fresh session defaults to. The prior fix (Data Bindings auto-expands
      first) was necessary but not sufficient: an empty, gated-away section
      has nothing to expand. Rewrote every `dataBindings`-category
      `PropertyMeta.minLevel` to `basic` (a small paren-depth-parsed script
      across 57 call sites, not hand-editing each one) — binding a widget's
      own displayed value is not an advanced concept, only its cosmetic/
      layout/font knobs still gate above Basic. Verified live: dropped a
      blank "Minimal" Text preset, confirmed "Value binding" is the first
      thing shown, pre-filled with a friendly name ("Battery Voltage
      (v_in)"), and that clicking it opens the full picker with every
      telemetry key plus free-text custom-variable entry.

---

## Full Studio UX audit (2026-09-17)

User feedback, most forceful yet: typing in a property field "can't even
make a space"; the whole program "feels clumsy," "unintuitive," "has no
overview"; named presets like "Porsche Green" "don't mean anything, they
are just the regular gauge with green"; the gauge can't be customized to a
different ring layout; "some widgets have weird unknown suffix's." Explicit
ask: a full audit of every widget kind and every property, reflecting
honestly on whether a user can build what they want entirely through the
UI — "USERS DONT SIT ON JSON FILES."

- [x] **FIXED — can't type a space in a text property**: `_LiteralEditor`
      committed on every keystroke (`onChanged`), which round-tripped
      through the parent and back via `didUpdateWidget`, overwriting
      `_controller.text` mid-typing — a trailing space is exactly the kind
      of edit that round-trip silently erases. Fixed by committing only on
      blur/submit via a `FocusNode` listener, matching every other property
      editor in the inspector. Regression test
      (`literal_editor_typing_test.dart`) verifies both the submit path and
      the blur path independently.
- [x] **Full property audit** (read all 23 widget kinds in
      `property_manifest.dart`, cross-checked each fixed-vocabulary string
      against the widget's actual rendering code): found two more raw-string
      properties with no picker — `image.fit` (`contain`/`cover`/`fill`/
      `fitWidth`/`fitHeight`/`none`) and `tripstats.layoutStyle`
      (`standard`/`3x3`/`porsche`) — both now have `options:` pickers, same
      pattern as the 10 fixed earlier. Also found a genuinely bigger gap,
      not a quick picker fix: `appgrid.apps` is a comma-separated mini-DSL
      (`name` or `name:label`, ~20 hardcoded internal codenames like
      `nav`/`sms`/`obd`) typed into one plain text field — exactly the
      "hand-edit a DSL string" problem this whole audit exists to catch.
      **Not yet fixed** — needs a real chip-style list-builder widget (add/
      remove app, pick name from a list, optional custom label), not a
      dropdown. Tracked as follow-up work below.
- [x] **FIXED — gauge ring/arc layout wasn't actually customizable**: the
      renderer already fully supports arbitrary ring geometry
      (`sweepAngle`/`startAngle`/`arcWidth`/`tickCount`/`needleStyle`, each
      with a proper slider), but every one of them required
      `CapabilityLevel.advanced` — invisible at the `basic` level every
      fresh session starts at, same root-cause shape as the Data Bindings
      bug two entries up. Promoted all five to `basic`. Also found and
      fixed: the Settings screen's capability-level dropdown claimed a
      change "applies on the next studio launch" — verified via a live
      widget-test probe that this was simply false, it already applies
      immediately in the same session. Fixed the misleading text, and
      added a live Basic/Advanced/Expert dropdown directly in the Canvas
      toolbar so the level (and what it unlocks) doesn't require a trip to
      Settings to see or change. Verified live end-to-end: dropped a bare
      gauge at Basic, confirmed Sweep/Ticks were already visible in
      Visuals without switching levels; switched the toolbar dropdown to
      Expert and watched it apply with no restart.
- [x] **FIXED — car-brand gauge presets were cosmetic-only recolors**:
      confirmed the complaint by reading the actual preset definitions —
      BMW Amber, Audi Sport, and Porsche Green all used the identical
      `sweepAngle: 270, startAngle: 135, needleStyle: 'needle'` geometry,
      differing only in colour, tick count, and label. Redesigned each with
      real structural differences: BMW is now a thin (arcWidth 5), dense-
      tick (20), near-full ring (300°/120°) — a precision-instrument look;
      Porsche is a thick (arcWidth 14), sparse-tick (8) near-full ring
      (310°/115°) — a bold, chunky tach; Audi keeps the classic 3/4 sweep
      but is the one preset using the gauge's previously-dead inner-ring
      feature, showing motor duty cycle as a second concentric ring
      alongside the main RPM needle. Verified live: all three rendered
      side-by-side are now visually and geometrically distinct, not
      recolors of one shape.
- [~] **"No overview, not intuitive" at the whole-program level**: not
      resolved this pass — see the capability-level removal entry directly
      below for one contributing piece of it. The broader complaint — no
      onboarding/tour, 20+ widget kinds with no guided starting point
      beyond the template gallery — is a real, larger design question this
      pass didn't have scope to fully resolve. Not claiming this is done.

**Answering the central question — can a user build any dashboard entirely
through the UI, no JSON required?** Yes, with one known exception. Every
data-binding value, every fixed-vocabulary property, and now the gauge's
ring geometry are reachable through real pickers/sliders in the inspector,
verified live rather than assumed. The one remaining place that still
requires typing a structured value into a text field is `appgrid.apps` —
tracked above, not yet fixed. Everything else audited this pass (23 widget
kinds, every property in `property_manifest.dart`, every named preset) is
either already UI-only or was fixed to be during this pass.

### Follow-up work (not done this pass)
- [ ] `appgrid.apps`: replace the comma-separated DSL text field with a
      real list-builder (chip list, add/remove, name picker + optional
      label per entry).
- [ ] Broader onboarding/overview pass — a guided first-run path beyond the
      template gallery, given 20+ widget kinds and three editor modes
      (Template/Canvas/Flow) with no explanation of when to use which.

## Capability-level (Basic/Advanced/Expert) system removed entirely (2026-09-17)

User feedback, immediately following the audit above: the just-added
Canvas-toolbar level dropdown ("There is no advanced anymore is there i
dont think there is a toggle") and a direct, unambiguous instruction —
remove the whole Basic/Advanced/Expert concept completely, it does not fit
this project.

Before removing, audited every `CapabilityLevel` consumer in the monorepo
to see what actually depended on it, rather than assuming the property
inspector was the only one:
- `PropertyMeta.minLevel` — **live**: this was the one thing actually
  filtering anything (the inspector).
- `WidgetInstance.level` (dashboard_model) — serialized into every saved
  `.veschub.json` as `"level": "basic"`, never read back anywhere.
- `DashboardTemplate.level` (dashboard_model/templates) — never consulted
  by `template_mode.dart` to filter the template gallery.
- `WidgetKind.level` (widgets_library's `builtInWidgets` registry) — never
  consulted by `studio_palette.dart`, which only ever reads `.keys`.
- `NodeKindDef.level` (node_graph's node catalog) — never consulted by
  `flow_mode.dart`.
- `transformsUnlockedAt()` and `WidgetDescriptor` — dead code, exercised
  only by their own tests, called from nowhere in the app.

So beyond the property inspector, the entire concept was inert scaffolding
that never gated anything — confirmed via `grep`, not assumed.

**Removed completely**, not hidden or defaulted differently:
`CapabilityLevel` enum, `PropertyMeta.minLevel` (and the `level` parameter
threaded through `visibleProperties`/`categorizedProperties`/
`propertiesByCategory`/`getPropertiesByCategory`), `WidgetInstance.level`,
`DashboardTemplate.level`, `WidgetKind.level`, `NodeKindDef.level`,
`SettingsService.capabilityLevel`/`setCapabilityLevel` and its persisted
pref key, `capabilityLevelProvider`, the Canvas-toolbar dropdown added
minutes earlier in this same pass, and the "Default capability level" row
in Settings. `transformsUnlockedAt`/`WidgetDescriptor` deleted as dead code
found along the way.

**Net effect**: every property is now shown for every widget, always —
there is nothing left to unlock. `EditorMode` (Template/Canvas/Flow, the
segmented toolbar switcher) is a separate, unrelated concept and is
unaffected by this removal.

Verified: `grep -rln "CapabilityLevel\|capabilityLevel"` across the entire
repo returns nothing; zero analyzer errors across all 19 melos packages
(`melos exec -- flutter analyze`); full test suites green in every
affected package, with tests that exercised the removed gating rewritten
to assert the new always-visible behavior rather than deleted outright.

---

## Backspace inside property fields was globally swallowed (2026-09-17)

User report: "Moving the sliders they dont change and dont save themselves
in the state they are slided too also i cant change the values properly
and cant backspace on the values either."

Reproduced live in the user's own running dashboard, then isolated in a
widget test rather than guessed at:
- **Slider dragging**: tested in isolation (drag a Ticks slider, read the
  committed value back from `sceneModelProvider`) and it persisted
  correctly, both before and after the fix below. No slider-specific bug
  found — most likely explained by the text-field bug below making the
  whole control feel broken, or a live drag missing the slider's hit area.
  Flagging this rather than claiming it's fixed when no root cause was
  found for it specifically.
- **FIXED — backspace did nothing inside any property text field**: root
  cause was `CanvasKeyboardShortcuts` (`apps/studio/lib/editor/
  keyboard_shortcuts.dart`), which binds Delete/Backspace via
  `CallbackShortcuts` to delete the selected canvas widget, guarded by a
  `_typing()` check so it wouldn't fire while a text field has focus. The
  guard worked — Backspace no longer deleted the whole widget while
  typing — but `CallbackShortcuts` consumes a matching key event the
  instant its activator matches, *regardless* of what the bound callback
  actually does, including a no-op. So the keystroke never reached the
  focused field's own backspace/delete-character handling either: not
  "safely ignored," just silently swallowed. Net effect verified via test:
  typing "105" into a numeric field and pressing Backspace left the field
  showing "105", unchanged.
  Fixed by omitting the Delete/Backspace bindings entirely while a text
  field has focus, rather than guarding the callback — the keystroke is
  then never claimed by the shortcut system and falls through to normal
  text editing. `CallbackShortcuts`' binding map is static per build, so
  `CanvasKeyboardShortcuts` became a stateful widget that listens to
  `FocusManager` and rebuilds on every focus change to keep the map
  current. Verified via the same test: the field now reads "10" after the
  same keystroke.
  Along the way, found and fixed a real gap in the *existing* regression
  test for this exact class of bug (`keyboard_shortcuts_test.dart`,
  originally added when Backspace used to delete the whole widget): it
  only asserted the widget wasn't deleted, never that the keystroke
  actually edited the text — exactly the blind spot that let this ship.
  Strengthened it, and added `slider_property_test.dart` covering the
  numeric-field case specifically.

## The real slider bug: the inspector never refreshed after a commit (2026-09-17)

The previous entry's "no slider-specific bug found" was wrong — the user
came back with "Still cant move the sliders at all" after restarting, and
pushed for a real fix rather than accepting the shrug. Re-reproduced live,
carefully this time: zoomed into a screenshot to get the slider thumb's
exact pixel position, then dragged with 20 granular intermediate mouse
moves rather than a single jump. The thumb still didn't move and the
readout still said "10.0" — **but the actual gauge preview on the canvas
re-rendered with a visibly denser ring of tick labels**, proving the
underlying value *had* changed (to somewhere near the slider's max) even
though the slider's own display never updated. That mismatch was the real
clue: the commit path was never broken, only the inspector's own display
of it.

**Root cause**: `_PropertiesInspector.build()` (`apps/studio/lib/editor/
studio_inspector.dart`) called `ref.read(sceneModelProvider)` — a one-time
snapshot — instead of `ref.watch(sceneModelProvider)`. Worse, being
declared as a `const` widget, it doesn't even get rebuilt by its parent's
own top-level rebuild (`StudioEditor` watches `commandStackProvider` and
re-runs `build()` on every command, but Flutter skips re-invoking `build()`
on an unchanged `const` widget instance entirely — there's nothing for the
parent rebuild to "reach"). So the inspector only ever refreshed when
`selectionModelProvider` itself changed; every property edit committed
correctly to the model (confirmed independently — the canvas preview,
which does watch the scene directly, always reflected changes instantly)
but the inspector kept displaying stale props otherwise. A `Slider` has no
local memory of its dragged position — its displayed value is purely
`(widget.value as num).clamp(min, max)` recomputed fresh every render — so
with a stale `widget.value` forever frozen, it visibly never moved. Text
fields and enum pickers partially masked the same underlying bug by
showing whatever the user just typed/selected locally in their own
`TextEditingController`/`Autocomplete` state, independent of whether the
"official" value ever round-tripped back into view.

**Fixed** with a one-line change (`read` → `watch`). Verified the fix
addresses the real mechanism, not just the symptom: wrote
`inspector_reactivity_test.dart`, which commits a property change directly
through the scene model (bypassing all UI interaction, isolating exactly
this reactivity gap) and asserts the rendered `Slider.value` reflects it.
Confirmed the test fails against the old `read` (expects 40.0, gets 10.0)
and passes against `watch`. Then live-verified end to end on a real
running build, using the same precise drag technique both times: with the
old code, the slider stayed stuck at "10.0" while the gauge rendering
changed underneath; with the fix, the slider and its readout both
correctly track to "43.0".

This also means every other property control in the inspector was subject
to the same staleness whenever a commit happened without the selection
changing — this fix isn't slider-specific, it's the inspector's whole
reactivity model being corrected.

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

- [x] VESC telemetry ingestion (16 of 16 base COMM_GET_VALUES keys, +4 GPS
      keys from a separate source — see Milestone 4's FOC-key fix)
- [x] Widget rendering in dashboard viewer
- [x] Cosmetic properties: backgroundColor, borderRadius, fontSize
- [x] Formula bindings: math expression evaluator (F(x) toggle)
- [x] Expandable inspector sections (Advanced / Expert)
- [x] JSON export / import (.veschub.json)
- [x] Pipeline integration tests (3 tests)
- [x] Settings: transport, auto-connect, data rate
- [ ] [P2] Flow mode: add script/Dart-expression tab alongside node graph —
      **still open as literally described; rescoped effort into a related,
      higher-value gap instead** (2026-09-13). Studied
      `evaluateGraph`/`FlowGraph` (node_graph package) and the existing
      Formula binding's `evaluateFormula` (dashboard_runtime) before
      starting: a text-entry "script" alternative to the node-graph canvas
      would directly duplicate what Formula bindings already do at the
      property level (both ultimately produce one value from an expression
      over telemetry) — building a second, competing UI for the same job
      without the node graph's actual advantage (multiple named outputs,
      reusable sub-graphs) seemed like the wrong investment.
  - Found the real, concrete gap instead: `evaluateFormula` — already used
        by every Formula-binding property in the whole app — had **no
        functions at all**, not even `min`/`max`/`clamp`. Only +, -, *, /,
        ^, parens, and telemetry-key identifiers. A user wanting to clamp a
        display range or take an absolute value had no way to do it in a
        formula at all.
  - Added `min(...)`, `max(...)`, `clamp(v, lo, hi)`, `abs(v)`, `round(v)`,
        `floor(v)`, `ceil(v)`, `sqrt(v)` to the expression grammar in
        `packages/dashboard_runtime/lib/src/formula_evaluator.dart` (a
        proper recursive-descent extension: function calls are
        `ident '(' args ')'`, checked before falling back to a telemetry-key
        lookup). Added a tooltip on the Formula editor's icon listing the
        available functions, and improved its hint text from the trivial
        `erpm / 1000` to `clamp(erpm / 1000, 0, 30)` so the new capability
        is actually discoverable, not just present.
  - This file had **zero existing tests** despite being used by every
        Formula binding in the app — added
        `dashboard_runtime/test/formula_evaluator_test.dart` (15 tests)
        covering both the pre-existing arithmetic behaviour (regression
        coverage it never had) and every new function, including argument-
        count validation and composition with telemetry lookups.
  - Verified: `flutter analyze` clean, `flutter test` in
        `packages/dashboard_runtime` (14 tests: 3 pre-existing + 11 new) and
        `apps/studio` (34 tests) both pass. The literal "Flow-mode script
        tab" UI is left undone — this is a deliberate rescoping, not a
        silent skip.
- [x] [P2] Flow mode: node-graph export/import (2026-09-13): `FlowGraph`
      already had `toJson`/`fromJson` (and an existing round-trip test in
      `node_graph/test/graph_test.dart`) — this was pure UI wiring, mirroring
      the already-working whole-document export/import pattern in
      `studio_editor.dart`. Added Export/Import icon buttons to the Flow mode
      toolbar, writing/reading a standalone `.flowgraph.json` (graph +
      per-node properties), distinct from the existing "Save graph" button
      (which embeds the graph in the current dashboard document) — so a
      graph can be built once and reused as a preset across dashboards. No
      dedicated test added: consistent with the existing whole-document
      export/import, which also has zero test coverage in this codebase
      (FilePicker's platform channel isn't mocked anywhere here). "Presets"
      (a curated built-in library of graphs, vs. just import/export of your
      own) and documentation are still open, smaller follow-ups. Script/
      Dart-expression tab (a separate, bigger, more speculative feature —
      likely overlapping with the property inspector's existing Formula
      binding) intentionally not attempted in this pass.

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
- [x] [P2] Dark / light theme obeying widget background colors (2026-09-13):
      `DashboardTheme`/`DashboardThemeProvider`/`ThemePreference` all already
      existed correctly designed, and `ThemeMode` was already wired into the
      real `MaterialApp` — but the real gap was one level deeper. Any widget
      that reads the ambient theme (`status`/`web`/`chart`, via
      `DashboardThemeProvider.of(context)`) silently fell back to the
      hardcoded `DashboardTheme.dark` default in the actual dashboard
      viewer, because `ViewerScreen` never provided one at all — so those
      widgets ignored both the document's own colors AND the user's light/
      dark preference, always dark regardless of app chrome. Fixed by
      wrapping the dashboard content in a `DashboardThemeProvider` built via
      `DashboardTheme.fromDocument`, with `brightness` taken from
      `Theme.of(context).brightness` (already correctly resolves
      `ThemeMode.system`) so user preference actually reaches widget-level
      theming. Added tests confirming a real (non-default) theme is
      provided, and that its brightness follows the resolved `ThemeMode`.
- [x] [P2] Metric / imperial unit conversion (per-widget, not global) (2026-09-13):
      same work as Milestone 10's "Per-widget unit system" item — see that
      entry. Covers speed (`digitalspeed`) and temperature (`minigauge`).
- [x] [P3] Dashboard app display modes — partial (2026-09-13): the two
      genuinely "Pi-optimized"/kiosk-relevant pieces. New
      `apps/dashboard/lib/display_settings.dart` (`DisplaySettings`,
      app-local — not `packages/settings`, since Studio never needs to know
      about these; same persisted-`ChangeNotifier` pattern as
      `SettingsService`): **keep screen awake** (via `wakelock_plus`,
      defaults on — a display mounted in a vehicle shouldn't sleep
      mid-drive) and **immersive fullscreen** (hides OS status/nav bars via
      `SystemChrome.setEnabledSystemUIMode`, defaults *off* since some
      devices need a swipe-from-edge gesture to reveal them again and that
      shouldn't be a surprise). Both exposed as toggles in a new "Display"
      settings section. The existing tap-top-edge-to-reveal auto-hiding
      toolbar already covered casual "mostly fullscreen" viewing.
  - **Not done** (left for a follow-up, deliberately not guessed at):
        splitscreen (rendering two dashboards side by side is a materially
        bigger feature — layout, a second `DashboardRuntime`/telemetry
        store, its own UI for picking the second dashboard — not a
        settings toggle); a dedicated "Pi-optimized" layout/density preset
        beyond keep-awake/immersive (unclear what this should concretely
        mean without a real Pi + small display to test against).
  - Verified: `flutter analyze` clean, `flutter test` (11 tests, 2 new
        files) and a Linux debug build both pass. `wakelock_plus` calls are
        wrapped in try/catch — a platform with no wakelock channel
        registered (a test environment, or a platform this plugin doesn't
        support) shouldn't crash a settings toggle over it; this is also
        what let the test suite exercise the real setter path without
        mocking the platform channel.

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
- [x] [P3] App-wide icon audit pass (2026-09-13): three real findings, no
      manufactured nitpicks. (1) Dashboard's top-bar title button
      (`Icons.dashboard`, "Veschub · \$docName") and its adjacent dedicated
      "Templates" button (`Icons.grid_view`) called the exact same
      `onShowTemplates` callback — two different icons, same row, same
      action. Nothing about tapping a dashboard's own name suggests it opens
      the template picker, so made the title plain (non-interactive) rather
      than picking one of the two icons to keep as a button. (2) Studio's
      "Delete widget" (Canvas inspector) used `delete_outline` while "Delete
      node" (Flow inspector) used filled `delete` for the identical action —
      aligned Flow to `delete_outline`. (3) The layer panel's overlap
      indicator used `warning_amber` next to a tooltip that explicitly says
      "often fine" — swapped for `info_outline` (already Studio's
      convention for this severity) so the icon doesn't oversell the
      problem. Per-widget-kind icons already centralized this session via
      `kindIcon()` were out of scope for this pass.

## Milestone 6: Navigation & GPS 🚧

- [x] [P2] GPS widget (speed, altitude, coordinates) (2026-09-13): a new
      `gps` kind (`gps_widget.dart`) — a compact composite panel distinct
      from the `map` kind's live tile view, showing speed (large), altitude,
      and lat/lon coordinates together, the way a real GPS-equipped
      instrument cluster does. Added `TelemetryKey.gpsAltitude` (`gps.
      altitude`) to complete the GPS namespace — `gpsLat`/`gpsLon`/
      `gpsSpeed`/`gpsHeading` already existed. Registered as a proper first-
      class kind (icon, description, property manifest, palette preset,
      category) following the exact same pattern as every other built-in
      widget — this is a legitimate composite (like `tripstats`/`climate`),
      not the kind of monolithic single-purpose widget flagged earlier this
      session, since combining a few related GPS readings into one panel is
      genuinely useful and the primitives (`text`/`minigauge`) remain
      equally available for anyone who'd rather build their own layout.
  - Found and fixed a real overflow bug while writing the widget test: my
        own first-draft "GPS Panel" preset (`220×120` box, `fontSize: 36`)
        overflowed its own default size — three stacked lines don't fit that
        tightly. Wrapped the content in `FittedBox(fit: BoxFit.scaleDown)`,
        the same defensive pattern `text_widget.dart`/`tripstats_widget.
        dart`/`digitalspeed_widget.dart` already use for exactly this
        failure mode, and bumped the preset's default box to `260×150`.
  - Seeded `gps.altitude`/`gps.speed` into both Studio preview telemetry
        stores alongside the existing `gps.lat`/`gps.lon`/`gps.heading`
        seeds (added for the map widget) so the preset renders meaningfully
        while editing.
  - Verified: `flutter analyze` clean (0 errors) across every touched file,
        `flutter test` in `packages/vesc_telemetry` (5 tests), `packages/
        widgets_library` (138 tests, 1 new file — including the manifest-
        drift and kind-description completeness checks, both of which
        exercise the new kind automatically), and `apps/studio` (34 tests)
        all pass. Confirmed live in the running app (screenshot on
        workspace 21): speed/altitude/coordinates all render correctly with
        no background box and no overflow.
- [x] [P2] Map widget (OpenStreetMap tile layer) (2026-09-13): the existing
      `map` kind's `_MapCanvasPainter` was purely decorative — hand-drawn
      fake roads, not a real map. Added `flutter_map`/`latlong2` and a new
      opt-in `mapStyle: 'osm'` code path (`_LiveMapTiles` in
      `map_widget.dart`) rendering real tiles from
      `tile.openstreetmap.org`, centred on new `lat`/`lon` properties (bind
      to `TelemetryKey.gpsLat`/`gpsLon`, which already existed and were
      unused by any widget until now), with a rotated position marker
      (`heading` property) and the on-map "© OpenStreetMap contributors"
      attribution OSM's tile usage policy requires. Default `mapStyle`
      unchanged (still the decorative graphic), so no existing dashboard's
      look changes. Added a "Live GPS Map" palette preset bound to the real
      `gps.*` telemetry keys, and seeded those keys into both Studio preview
      telemetry stores (canvas + template) so the preset actually renders
      live tiles while editing, not just once deployed. When `lat`/`lon`
      aren't bound yet, shows a "No GPS fix yet" placeholder rather than
      attempting to render a map with no centre.
  - **Deliberately no automated test renders real tiles**: doing so would
        make the test suite depend on genuine network access to
        `tile.openstreetmap.org` (flakiness, OSM rate limits, CI policy) —
        `map_widget_test.dart` covers the two paths that don't touch the
        network (decorative-by-default, and the no-GPS-fix placeholder) and
        documents why the live-tile path isn't covered there. Verified the
        live-tile path instead by rebuilding the real Linux binary, dropping
        the preset in a live-launched window, and confirming actual OSM
        tiles rendered (Berlin, matching the seeded coordinates) with the
        marker and attribution both correct.
  - Verified: `flutter analyze` clean across all three touched files,
        `flutter test` in `packages/widgets_library` (134 tests, 1 new
        file), `apps/studio` (34 tests), `tools/dashboard_renderer`
        (10 tests, unaffected), and `apps/dashboard` (11 tests, unaffected)
        all pass.
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
- [x] [P2] Template typographic identity per car brand (2026-09-13): design
      feedback was that the 9 advanced/car-brand templates "kinda look
      similar" beyond color — confirmed the root cause was literal: zero
      widget instances in `advanced_templates.dart` set `fontWeight` or
      `letterSpacing`, so every template fell back to the same per-widget
      default regardless of brand. Added both as literal properties on every
      text-bearing widget instance (`gauge`, `text`, `tripstats`,
      `minigauge`, `battery_range`, `gear_selector` — the kinds actually
      present in this file that call `applyTextStyle`; `digitalspeed`,
      `power`, `status`, `climate` aren't used by any instance here, and
      `bar` was dropped despite being on the original candidate list because
      `bar_widget.dart`'s value label uses a hardcoded `TextStyle`, not
      `applyTextStyle`, so the properties would have been silently ignored;
      `car_viz`/`statusbar` do call `applyTextStyle` for one minor sub-label
      but were left out of scope per the brief). `fontFamily` stays the
      shared bundled Rajdhani base app-wide (separate change) — this pass is
      weight/spacing only, one fixed pair per template so it reads as a
      system:
      | template | fontWeight | letterSpacing |
      |---|---|---|
      | tesla-model3 | w300 | -0.5 |
      | porsche-taycan | w500 | 0.3 |
      | bmw-classic | w700 | 1.0 |
      | audi-virtual-cockpit | w300 | 1.5 |
      | vesc-mobile | w500 | 0.0 |
      | android-auto | w500 | 0.0 |
      | carplay | w600 | -0.2 |
      | ford-digital | w700 | 0.0 |
      | vw-digital | w500 | 0.3 |
      59 widget instances touched across the 9 templates. Verified
      `examples/*.veschub.json` (the dashboard_renderer golden fixtures) are
      a separate static copy, not generated from this file — golden tests
      ran unchanged, no regeneration needed. `built_in_templates.dart` (the
      4 generic starters) intentionally untouched.
- [x] [P3] In-app "what does this property do" — text descriptions done,
      preview thumbnails not (2026-09-13). The property-row tooltip
      (added earlier this session) just echoed the label and raw key back
      (`Property "Background" (backgroundColor)`) — no actual explanation.
      Added `packages/widgets_library/lib/src/property_descriptions.dart`:
      `propertyDescription(key, fallbackLabel)`, a genuine one-line
      explanation for ~90 property concepts, keyed by *base* key (numbered
      slots like `label1`..`label4`, `unit2_3`, `section1Header` all
      normalise to the same description as `label`/`unit`/`sectionHeader` —
      most multi-stat widgets repeat a handful of concepts across 3-4 numbered
      slots, so this covers far more of the actual 153 distinct manifest keys
      than the count suggests) with a sensible fallback to the manifest label
      for the long tail of one-off, highly kind-specific keys not worth a
      bespoke entry. Visual preview thumbnails (an actual before/after image
      per property) are a much bigger content-authoring investment and
      weren't attempted — flagging rather than guessing at scope for that
      part. Verified: `flutter analyze` clean, `flutter test` in `packages/
      widgets_library` (132 tests, 1 new file) and `apps/studio` (34 tests)
      both pass.

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
