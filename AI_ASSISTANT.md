# AI Dashboard Assistant — Design

Status: planned (Milestone 9 in `ROADMAP.md`). Not yet implemented.

## Goal

Let someone build a dashboard by describing what they want instead of only
dragging widgets manually — without becoming a second, competing way to edit
a document that can drift from the "real" one. The assistant is Studio-only.
The Dashboard runtime app (`apps/dashboard`) never talks to it and has no new
dependency because of it.

Two modes, matching how much control the user wants to hand over:

- **Guidance mode** — a copilot alongside manual editing. The user keeps
  driving; the assistant answers questions, spots problems, and proposes
  small, reviewable edits ("bind this gauge's value to `erpm`", "this text
  widget has no binding — want me to fix that?").
- **Auto mode** — the user describes a whole dashboard (or a big change) in
  one prompt; the assistant runs an agentic loop and produces a complete
  result, presented as one batch the user accepts or discards.

Both modes are the *same* underlying mechanism run at different scopes — a
turn-limited, reviewed batch of tool calls (Guidance) vs. a longer
unsupervised loop that still lands as one undoable batch (Auto). This keeps
us from building two separate integrations.

## The core idea: the AI never writes documents directly

`DashboardDocument` / `WidgetInstance` (`packages/dashboard_model/lib/src/document.dart`)
is freezed+JSON and already round-trips through `.veschub.json`. It would be
tempting to have the model just emit a document JSON blob. Don't — that:

- bypasses `property_manifest.dart` validation (nothing stops it inventing a
  property that doesn't exist, or a value outside `min`/`max`)
- bypasses canvas-bounds clamping
- isn't undoable — a bad generation would need a full document revert, not
  Ctrl+Z
- can't be used incrementally for Guidance mode's "here's one small
  suggestion" case

Instead, the assistant is given **tools that map 1:1 to the existing
`EditorCommand` subclasses** in `packages/editor_canvas/lib/src/command_stack.dart`:

| Claude tool | Existing command | Notes |
|---|---|---|
| `add_widget` | `AddNodeCommand` | kind + initial transform + initial properties, filled from manifest defaults |
| `remove_widgets` | `RemoveNodesCommand` | by id |
| `set_transform` | `TransformNodesCommand` | position/scale (rotation once Milestone 5's rotation field lands) |
| `update_properties` | `UpdateNodeDataCommand` | one or more property keys on one widget |
| `reorder_z` | `ReorderCommand` | z-order changes |
| `apply_template` | (existing template application path in `apps/studio/lib/editor/template_mode.dart`) | for "start from X, then customize" |

Every tool call is validated **before** it reaches the command stack:
1. `kind` must exist in the widget registry.
2. Every property key in `update_properties`/`add_widget` must exist in that
   kind's `PropertyMeta` list (`property_manifest.dart`); reject unknown keys.
3. Numeric values are clamped to the property's `min`/`max` if declared.
4. Transforms are clamped to stay within canvas bounds (reuse the existing
   clamp logic already used for manual drag — don't reimplement it).

Because every AI action is just a normal `EditorCommand`, it is automatically
undoable, automatically shows up correctly in the canvas/inspector, and can
never produce a document the manual editor itself couldn't produce.

## Architecture

New package: **`packages/ai_assistant`** (Studio depends on it; no other
app/package does).

```
packages/ai_assistant/
  lib/
    src/
      claude_client.dart      # thin wrapper over the Messages API (http package)
      tool_definitions.dart   # JSON schemas for the 6 tools above
      tool_executor.dart      # validates + dispatches a tool call onto CommandStack
      context_builder.dart    # assembles the system prompt
      assistant_session.dart  # one guidance/auto "turn" or "run"
    ai_assistant.dart
```

- **`claude_client.dart`**: raw HTTP POST to the Messages API with tool-use
  enabled (avoid pulling in a heavy SDK for one endpoint). API key comes from
  `packages/settings` (new `aiApiKey` field), entered in Studio Settings —
  never hardcoded, never shipped in the Dashboard runtime app.
- **`context_builder.dart`** assembles, per turn:
  - the current `DashboardDocument` as JSON (so the model sees exactly what's
    on canvas)
  - the categorized property manifest for every kind currently in play (so it
    only ever proposes real properties)
  - `TelemetryKey.all` (from `packages/vesc_telemetry`) so bindings reference
    real keys
  - the list of built-in templates (`packages/templates`) for `apply_template`
- **`tool_executor.dart`** is the validation gate described above; it's the
  only piece that touches `CommandStack`, so there's exactly one code path
  from "AI decided something" to "document changed."
- **`assistant_session.dart`** runs the loop: send context + user message →
  get tool calls → validate + execute → (Guidance: stop and show the user
  what happened; Auto: feed tool results back and let the model continue,
  up to a turn cap, e.g. 20) → final summary shown to the user.

## UI

- A mode toggle next to the existing Template/Canvas/Flow switch, or a
  dedicated "Ask AI" panel (side drawer) — exact placement is a UI decision
  to make once this is being built, not before. Recommend a right-side
  drawer so it doesn't compete with the canvas/inspector layout.
- **Guidance mode**: chat-style panel. Each assistant turn shows a small diff
  ("added `battery_range` widget, bound `level` → `v_in`") with Accept/Undo,
  before or immediately after applying — since it's a real `EditorCommand`,
  "Undo" is just the existing undo stack.
- **Auto mode**: a single prompt box ("Tesla-style dashboard with battery
  range and gear selector"). Runs the full loop, then shows the resulting
  canvas with everything selected and a single "Keep" / "Undo all" (undo all
  = pop N commands off the stack, where N is what the run pushed).
- Inline hints (Milestone 9's `[P2]` item) are a lighter-weight, non-chat
  surface: small warning icons in the inspector for things like "no binding
  set" — these can literally just check the manifest + document, no LLM call
  needed for the common cases, and only escalate to the assistant for advice
  the user explicitly asks for.

## What this does NOT do (v1 scope)

- No autonomous *hardware* actions — the assistant only edits the
  `DashboardDocument`, never touches transport/BLE/USB code (Milestone 3 is
  sidetracked anyway).
- No document-structure changes outside the existing schema (no new fields on
  `WidgetInstance` invented by the model) — if a real gap is found (e.g. no
  rotation field yet), that's a manifest/schema change made by a person, not
  something the assistant papers over.
- No network dependency in `apps/dashboard` — confirm this stays true in
  review; it's the whole point of keeping this Studio-only.

## Build order

1. `packages/ai_assistant` skeleton + `claude_client.dart` + tool schemas,
   unit-tested against `tool_executor.dart` validation (no UI yet, no live
   API calls in tests — mock the HTTP layer).
2. Guidance mode UI: chat panel wired to a live single-turn loop.
3. Guardrail hardening: clamp/validation edge cases, manifest-audit test from
   Milestone 5 doubles as protection here too (a tool call for an
   unaudited property should be rejected the same way a manual edit would be).
4. Auto mode: extend `assistant_session.dart` to the multi-turn loop, add the
   prompt-box UI and batch accept/undo.
5. Only after 1–4 are solid: revisit the "match this reference image" stretch
   goal, which reuses the AIdashboards-era screenshot workflow
   (`tools/dashboard_renderer`) to compare a generated dashboard against a
   target image.
