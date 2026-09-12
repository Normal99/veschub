# Project: Veschub Studio Widget Templates & Intuitive Properties UI

## Architecture
- `packages/widgets_library`: Core widget implementations and `property_manifest.dart` (`PropertyMeta`, `PropertyCategory` enum, categorized manifest definitions for all 11 widget kinds).
- `apps/studio`: Veschub Studio application containing `studio_editor.dart` (Property Inspector UI `_PropertiesInspector`, `_BindingField`, `_LiteralEditor`, color pickers, sliders, binding pickers, palette templates `_templates`, `_defaultProperties`).
- `packages/templates`: Built-in starter dashboard templates (`minimal`, `performance`, `commuter`, `offroad`, `advanced_templates`).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Property Category Schema | Add `PropertyCategory` enum and getter/field to `PropertyMeta` in `packages/widgets_library` | M1 | survey (R1) |
| 2 | Categorized Manifests (11 Kinds) | Define explicit property categories (Visuals, Data Bindings, Layout & Spacing, Fonts & Colors) across gauge, bar, text, chart, status, minigauge, battery_range, tripstats, car_viz, power_flow, gear_selector | M1 | survey (R1) |
| 3 | CarViz Missing Properties | Add missing `doorLeft`, `doorRight`, `showRing`, `showLabels`, `fontSize` to `car_viz` manifest | M1 | survey (R1) |
| 4 | Studio Categorized Property Inspector | Update `_PropertiesInspector` in Studio to render grouped, collapsible accordion sections by category | M2 | survey (R2) |
| 5 | Inspector Tooltips | Add `Tooltip` widgets to all property inspector rows and controls | M2 | survey (R2) |
| 6 | Enhanced Color Picker & Controls | Add hex entry (`#RRGGBB`) and color swatches to color picker control | M2 | survey (R2) |
| 7 | Number Sliders & Controls | Add slider control support for numeric properties with min/max/step ranges | M2 | survey (R2) |
| 8 | Enhanced Binding Pickers | Improve telemetry dropdown with category grouping/search and graph picker | M2 | survey (R2) |
| 9 | Complete Out-of-the-box Defaults | Update `_defaultProperties(kind)` in `studio_editor.dart` for all 11 widget kinds so zero kinds fall back to empty maps | M3 | survey (R3) |
| 10 | Widget Palette & Template Scaffolds | Audit and polish palette presets `_templates` and starter presets in `packages/templates` | M3 | survey (R3) |
| 11 | E2E & Automated Test Suite | Comprehensive unit/widget test verification across packages via `melos exec -- flutter test` and manifest validation | M4 | survey |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Property Manifests & Categorization | Refine `PropertyMeta` schema and populate categories across all 11 widget kinds in `packages/widgets_library` | none | PLANNED |
| 2 | M2: Studio Property Panel UI & Controls | Upgrade `_PropertiesInspector`, tooltips, color picker, sliders, and binding pickers in `apps/studio` | M1 | PLANNED |
| 3 | M3: Starter Defaults & Template Scaffolds | Audit and populate default values for all 11 widget kinds and polish starter templates in `apps/studio` and `packages/templates` | M1, M2 | PLANNED |
| 4 | M4: Final E2E Test Suite & Verification | Pass 100% of unit tests (`melos exec -- flutter test`), validate categorized manifests, verify Studio launch | M1, M2, M3 | PLANNED |

## Interface Contracts
### `packages/widgets_library` ↔ `apps/studio`
- `PropertyCategory` enum with values: `visuals`, `dataBindings`, `layoutAndSpacing`, `fontsAndColors`.
- `PropertyMeta` field/getter `category` of type `PropertyCategory`.
- `PropertyMeta` optional range metadata (`min`, `max`, `step`) for numeric properties.
- `WidgetManifest` method/getter `categorizedProperties` or `propertiesByCategory` returning `Map<PropertyCategory, List<PropertyMeta>>`.

## Code Layout
- `packages/widgets_library/lib/src/property_manifest.dart`: `PropertyMeta`, `PropertyCategory`, and manifest definitions.
- `packages/widgets_library/lib/widgets/`: Widget implementations.
- `apps/studio/lib/editor/studio_editor.dart`: `_PropertiesInspector`, `_BindingField`, property controls, `_defaultProperties`, `_templates`.
- `apps/studio/lib/widgets/`: Property controls (`simple_color_picker.dart`, etc.).
- `packages/templates/lib/src/`: Starter templates.
