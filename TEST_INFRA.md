# E2E Test Infra: Veschub Studio Widget Templates & Properties UI

## Test Philosophy
- Opaque-box & unit test validation derived from user requirements in ORIGINAL_REQUEST.md and PROJECT.md.
- Continuous verification across all 11 core widget kinds (`gauge`, `bar`, `text`, `chart`, `status`, `minigauge`, `battery_range`, `tripstats`, `car_viz`, `power_flow`, `gear_selector`) and Studio Property Inspector UI.
- Systematic 4-Tier Testing Methodology:
  - Tier 1: Feature Coverage (≥5 test cases per feature across property categorization, inspector UI, defaults, and starter templates).
  - Tier 2: Boundary & Corner Cases (≥5 test cases per feature covering edge values, empty maps, invalid inputs, overflow, and color hex parsing).
  - Tier 3: Cross-Feature Combinations (Pairwise testing of manifest categorization, inspector controls, binding updates, and palette presets).
  - Tier 4: Real-World Application Scenarios (Realistic dashboard rendering, template loading, and live telemetry binding updates).

## Feature Inventory & Coverage Goals
| # | Feature | Source (Requirement) | Tier 1 Goals | Tier 2 Goals | Tier 3 Goals | Tier 4 Goals |
|---|---------|----------------------|:------------:|:------------:|:------------:|:------------:|
| 1 | Property Category Schema & Manifests | R1 (PROJECT §F1, F2, F3) | 5 | 5 | ✓ | ✓ |
| 2 | Studio Property Panel & Controls | R2 (PROJECT §F4, F5, F6, F7, F8) | 5 | 5 | ✓ | ✓ |
| 3 | Starter Defaults & Template Scaffolds | R3 (PROJECT §F9, F10) | 5 | 5 | ✓ | ✓ |

## Test Architecture & Structure
- Test Runner: `melos exec -- flutter test`
- Package Scope:
  - `packages/widgets_library/test/`: Manifest categorization tests across all 11 widget kinds, fallback values, and `PropertyMeta` category validation.
  - `apps/studio/test/`: Property inspector widget tests, control interactions (sliders, color pickers, tooltips, binding pickers), and starter preset default properties.
  - `packages/templates/test/`: Starter dashboard template integrity and preset serialization tests.
- Test Suite Plan:
  - `packages/widgets_library/test/property_manifest_categorization_test.dart` (Tier 1 & Tier 2)
  - `apps/studio/test/property_inspector_widget_test.dart` (Tier 1 & Tier 2)
  - `apps/studio/test/default_properties_and_templates_test.dart` (Tier 1 & Tier 2)
  - `packages/widgets_library/test/cross_feature_manifest_inspector_test.dart` (Tier 3)
  - `apps/studio/test/real_world_template_scenarios_test.dart` (Tier 4)

## Coverage Thresholds & Pass Criteria
- Tier 1: ≥15 test cases (≥5 per feature domain)
- Tier 2: ≥15 test cases (boundary & edge cases)
- Tier 3: ≥5 cross-feature interaction test cases
- Tier 4: ≥5 realistic dashboard E2E application scenarios
- Total Test Threshold: ≥40 comprehensive test cases
- Execution Pass Requirement: 100% clean exit code 0 via `melos exec -- flutter test`
