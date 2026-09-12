import 'package:dashboard_model/dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  const coreKinds = [
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

  group('Tier 1: PropertyCategory Enum & Schema Coverage', () {
    test('T1.1: PropertyCategory enum defines 4 distinct UI categories', () {
      expect(PropertyCategory.values.length, equals(4));
      expect(
        PropertyCategory.values,
        containsAll([
          PropertyCategory.visuals,
          PropertyCategory.dataBindings,
          PropertyCategory.layoutAndSpacing,
          PropertyCategory.fontsAndColors,
        ]),
      );
      expect(PropertyCategory.visuals.label, equals('Visuals'));
      expect(PropertyCategory.dataBindings.label, equals('Data Bindings'));
      expect(PropertyCategory.layoutAndSpacing.label, equals('Layout & Spacing'));
      expect(PropertyCategory.fontsAndColors.label, equals('Fonts & Colors'));
    });

    test('T1.2: Every core widget manifest property maps to a valid PropertyCategory', () {
      for (final kind in coreKinds) {
        final props = propertyManifest[kind];
        expect(props, isNotNull, reason: 'Manifest missing for widget kind $kind');
        expect(props, isNotEmpty, reason: 'Manifest empty for widget kind $kind');

        for (final meta in props!) {
          expect(meta.category, isA<PropertyCategory>(),
              reason: 'Property "${meta.key}" in widget kind "$kind" missing category');
        }
      }
    });

    test('T1.3: categorizedProperties groups gauge manifest correctly across all 4 categories', () {
      final categorized = categorizedProperties('gauge');
      expect(categorized.keys.length, equals(4));

      final visualKeys = categorized[PropertyCategory.visuals]!.map((m) => m.key).toList();
      final bindingKeys = categorized[PropertyCategory.dataBindings]!.map((m) => m.key).toList();
      final layoutKeys = categorized[PropertyCategory.layoutAndSpacing]!.map((m) => m.key).toList();
      final fontColorKeys = categorized[PropertyCategory.fontsAndColors]!.map((m) => m.key).toList();

      // min/max are dataBindings — they define the data range, not appearance
      expect(bindingKeys, containsAll(['value', 'min', 'max', 'centerValue', 'innerValue']));
      expect(visualKeys, containsAll(['sweepAngle', 'startAngle', 'tickCount', 'label', 'unit']));
      expect(layoutKeys, containsAll(['width', 'height', 'padding', 'borderRadius', 'opacity']));
      expect(fontColorKeys, containsAll(['color', 'accent', 'fontSize']));
    });

    test('T1.4: car_viz manifest contains core car visualization properties and category mappings', () {
      final carVizProps = propertyManifest['car_viz'];
      expect(carVizProps, isNotNull);
      final metaByKey = {for (final p in carVizProps!) p.key: p};

      expect(metaByKey.keys, containsAll([
        'laneLeft',
        'laneRight',
        'carAhead',
        'doorLeft',
        'doorRight',
        'showRing',
        'showLabels',
        'label',
        'fontSize',
        'color',
        'accent',
        'backgroundColor',
        'borderRadius',
        'width',
        'height',
      ]));

      // Verify category mapping directly on exported PropertyMeta.category
      expect(metaByKey['doorLeft']?.category, equals(PropertyCategory.dataBindings));
      expect(metaByKey['doorRight']?.category, equals(PropertyCategory.dataBindings));
      expect(metaByKey['showRing']?.category, equals(PropertyCategory.visuals));
      expect(metaByKey['showLabels']?.category, equals(PropertyCategory.visuals));
      expect(metaByKey['fontSize']?.category, equals(PropertyCategory.fontsAndColors));
    });

    test('T1.5: PropertyMeta specifies min, max, step bounds for numeric properties', () {
      final gaugeProps = propertyManifest['gauge']!;
      final fontSizeMeta = gaugeProps.firstWhere((p) => p.key == 'fontSize');
      expect(fontSizeMeta.min, equals(8.0));
      expect(fontSizeMeta.max, equals(96.0));
      expect(fontSizeMeta.step, equals(1.0));

      final opacityMeta = gaugeProps.firstWhere((p) => p.key == 'opacity');
      expect(opacityMeta.min, equals(0.0));
      expect(opacityMeta.max, equals(1.0));
      expect(opacityMeta.step, equals(0.05));

      final sweepAngleMeta = gaugeProps.firstWhere((p) => p.key == 'sweepAngle');
      expect(sweepAngleMeta.min, equals(10.0)); // min 10 ensures gauge is always visible
      expect(sweepAngleMeta.max, equals(360.0));
    });
  });

  group('Tier 2: Property Categorization Boundary & Corner Cases', () {
    test('T2.1: categorizedProperties filters properties by CapabilityLevel', () {
      final basicGauge = categorizedProperties('gauge', level: CapabilityLevel.basic);
      final basicBindings = basicGauge[PropertyCategory.dataBindings]!.map((m) => m.key).toSet();
      final basicVisuals = basicGauge[PropertyCategory.visuals]!.map((m) => m.key).toSet();

      // min/max are in dataBindings (they define the data range)
      expect(basicBindings, containsAll(['min', 'max']));
      // sweepAngle is Advanced level, so it must be filtered out in basic level
      expect(basicVisuals.contains('sweepAngle'), isFalse);
    });

    test('T2.2: Unknown widget kind returns empty categorized lists without throwing exception', () {
      final result = categorizedProperties('nonexistent_widget_kind');
      expect(result, isA<Map<PropertyCategory, List<PropertyMeta>>>());
      for (final category in PropertyCategory.values) {
        expect(result[category], isEmpty);
      }
    });

    test('T2.3: Non-numeric property keys return null range constraints', () {
      final gaugeProps = propertyManifest['gauge']!;
      expect(gaugeProps.firstWhere((p) => p.key == 'label').min, isNull);
      expect(gaugeProps.firstWhere((p) => p.key == 'color').min, isNull);
      expect(gaugeProps.firstWhere((p) => p.key == 'visible').min, isNull);
    });

    test('T2.4: Property keys within each of the 11 manifests are unique without duplicates', () {
      for (final kind in coreKinds) {
        final props = propertyManifest[kind]!;
        final keys = props.map((p) => p.key).toList();
        final uniqueKeys = keys.toSet();
        expect(keys.length, equals(uniqueKeys.length),
            reason: 'Duplicate property keys found in manifest for $kind');
      }
    });

    test('T2.5: All 11 core widget manifests populate at least 3 out of 4 property categories', () {
      for (final kind in coreKinds) {
        final catMap = categorizedProperties(kind);
        final populatedCount = catMap.entries.where((e) => e.value.isNotEmpty).length;
        expect(populatedCount, greaterThanOrEqualTo(3),
            reason: '$kind manifest has fewer than 3 populated categories');
      }
    });
  });
}
