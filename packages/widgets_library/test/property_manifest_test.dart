import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  const target11Kinds = [
    'gauge',
    'bar',
    'text',
    'chart',
    'status',
    'minigauge',
    'battery_range',
    'tripstats',
    'car_viz',
    'power_flow',
    'gear_selector',
  ];

  group('allProperties', () {
    test('gauge exposes its value binding alongside cosmetic properties', () {
      final all = allProperties('gauge');
      final keys = all.map((m) => m.key).toSet();
      expect(
          keys,
          containsAll(
              ['value', 'min', 'max', 'label', 'unit', 'color', 'accent']));
    });

    test('unknown kind returns empty list', () {
      expect(allProperties('nonsense'), isEmpty);
    });
  });

  group('propertyManifest completeness', () {
    test('every widget kind in the registry has a manifest', () {
      for (final kind in builtInWidgets.keys) {
        expect(
          propertyManifest.containsKey(kind),
          isTrue,
          reason: 'No manifest for widget kind "$kind"',
        );
      }
    });
  });

  group('PropertyCategory & PropertyMeta Schema', () {
    test('PropertyCategory enum values and display names', () {
      expect(PropertyCategory.values.length, 4);
      expect(PropertyCategory.visuals.displayName, 'Visuals');
      expect(PropertyCategory.dataBindings.displayName, 'Data Bindings');
      expect(PropertyCategory.layoutAndSpacing.displayName, 'Layout & Spacing');
      expect(PropertyCategory.fontsAndColors.displayName, 'Fonts & Colors');
    });

    test(
        'PropertyMeta category field is mandatory and non-null for all manifests',
        () {
      for (final entry in propertyManifest.entries) {
        for (final meta in entry.value) {
          expect(
            meta.category,
            isNotNull,
            reason:
                'Property "${meta.key}" in widget "${entry.key}" missing category',
          );
          expect(
            PropertyCategory.values.contains(meta.category),
            isTrue,
            reason:
                'Property "${meta.key}" in widget "${entry.key}" has invalid category',
          );
        }
      }
    });
  });

  group('Target 11 Widget Kinds Categorization', () {
    test('all 11 target widget kinds are present and non-empty', () {
      for (final kind in target11Kinds) {
        expect(propertyManifest.containsKey(kind), isTrue,
            reason: 'Missing manifest for "$kind"');
        expect(allProperties(kind).isNotEmpty, isTrue,
            reason: 'Empty manifest for "$kind"');
      }
    });

    test(
        'all 11 target widget kinds have properties across multiple categories',
        () {
      for (final kind in target11Kinds) {
        final grouped = propertiesByCategory(kind);
        expect(grouped[PropertyCategory.dataBindings], isNotNull);
        expect(grouped[PropertyCategory.visuals], isNotNull);
        expect(grouped[PropertyCategory.layoutAndSpacing], isNotNull);
        expect(grouped[PropertyCategory.fontsAndColors], isNotNull);

        expect(grouped[PropertyCategory.dataBindings], isNotEmpty,
            reason: '$kind missing dataBindings');
        expect(grouped[PropertyCategory.visuals], isNotEmpty,
            reason: '$kind missing visuals');
        expect(grouped[PropertyCategory.layoutAndSpacing], isNotEmpty,
            reason: '$kind missing layoutAndSpacing');
        expect(grouped[PropertyCategory.fontsAndColors], isNotEmpty,
            reason: '$kind missing fontsAndColors');
      }
    });
  });

  group('car_viz Manifest Expansion', () {
    test(
        'car_viz includes missing properties doorLeft, doorRight, showRing, showLabels, fontSize',
        () {
      final keys = allProperties('car_viz').map((m) => m.key).toSet();
      expect(
          keys,
          containsAll(
              ['doorLeft', 'doorRight', 'showRing', 'showLabels', 'fontSize']));

      final doorLeftMeta =
          allProperties('car_viz').firstWhere((m) => m.key == 'doorLeft');
      expect(doorLeftMeta.category, PropertyCategory.dataBindings);

      final doorRightMeta =
          allProperties('car_viz').firstWhere((m) => m.key == 'doorRight');
      expect(doorRightMeta.category, PropertyCategory.dataBindings);

      final showRingMeta =
          allProperties('car_viz').firstWhere((m) => m.key == 'showRing');
      expect(showRingMeta.category, PropertyCategory.visuals);

      final showLabelsMeta =
          allProperties('car_viz').firstWhere((m) => m.key == 'showLabels');
      expect(showLabelsMeta.category, PropertyCategory.visuals);

      final fontSizeMeta =
          allProperties('car_viz').firstWhere((m) => m.key == 'fontSize');
      expect(fontSizeMeta.category, PropertyCategory.fontsAndColors);
      expect(fontSizeMeta.min, 8.0);
      expect(fontSizeMeta.max, 96.0);
      expect(fontSizeMeta.step, 1.0);
    });
  });

  group('propertiesByCategory and categorizedProperties helper functions', () {
    test('returns properties grouped by category preserving total count', () {
      final grouped = propertiesByCategory('gauge');
      final totalGroupedCount =
          grouped.values.fold<int>(0, (sum, list) => sum + list.length);
      expect(totalGroupedCount, allProperties('gauge').length);

      final catGrouped = categorizedProperties('gauge');
      expect(catGrouped.length, PropertyCategory.values.length);
    });

    test('returns empty lists for unknown widget kind', () {
      final grouped = propertiesByCategory('nonsense');
      for (final cat in PropertyCategory.values) {
        expect(grouped[cat], isEmpty);
      }
    });
  });

  group('getPropertiesByCategory helper function', () {
    test('returns exact list of properties for category', () {
      final fontProps =
          getPropertiesByCategory('text', PropertyCategory.fontsAndColors);
      final keys = fontProps.map((m) => m.key).toSet();
      expect(
          keys, containsAll(['fontSize', 'fontFamily', 'fontWeight', 'color']));
    });

    test('returns empty list for unknown kind', () {
      final props =
          getPropertiesByCategory('unknown', PropertyCategory.visuals);
      expect(props, isEmpty);
    });
  });

  group('WidgetManifest OOP Abstraction', () {
    test('WidgetManifest.forKind creates valid manifest instance', () {
      final manifest = WidgetManifest.forKind('bar');
      expect(manifest.kind, 'bar');
      expect(manifest.categorizedProperties.keys,
          containsAll(PropertyCategory.values));
      expect(manifest.getPropertiesByCategory(PropertyCategory.dataBindings),
          isNotEmpty);
    });
  });
}
