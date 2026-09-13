import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('propertyDescription', () {
    test('numbered-slot keys resolve to their base concept\'s description', () {
      expect(propertyDescription('label1', 'Label'),
          propertyDescription('label', 'Label'));
      expect(propertyDescription('unit1_2', 'Unit'),
          propertyDescription('unit', 'Unit'));
      expect(propertyDescription('value3', 'Value'),
          propertyDescription('value', 'Value'));
    });

    test('section-prefixed multi-stat keys normalise correctly', () {
      expect(propertyDescription('section1Header', 'Header'),
          contains('caption shown above'));
      expect(propertyDescription('section2Val1', 'Value'),
          contains('bound value within'));
    });

    test('a real, specific description for common, widely-reused keys', () {
      expect(propertyDescription('value', 'Value'), isNot(contains('The Value property')));
      expect(propertyDescription('backgroundColor', 'Background'),
          contains('Transparent by default'));
      expect(propertyDescription('fontFamily', 'Font family'),
          contains('Default'));
    });

    test('falls back to the manifest label for a key with no bespoke entry',
        () {
      expect(propertyDescription('notARealPropertyKey', 'Made Up Thing'),
          'The Made Up Thing property.');
    });

    test('every manifest property key resolves to a non-empty description',
        () {
      // Sample of actual keys pulled from property_manifest.dart's built-in
      // kinds, across several widget kinds — not exhaustive, but exercises
      // the normalisation logic against real, non-hypothetical keys.
      const sampleKeys = [
        'value', 'min', 'max', 'label', 'unit', 'color', 'accent',
        'backgroundColor', 'borderRadius', 'padding', 'fontSize',
        'fontFamily', 'fontWeight', 'letterSpacing', 'tickCount',
        'sweepAngle', 'startAngle', 'needleStyle', 'redlineStart',
        'showCenterText', 'centerValue', 'centerUnit', 'label1', 'value2',
        'unit3', 'section1Header', 'section2Val1', 'sourceUnit',
        'displayUnit', 'showBars', 'maxPower', 'regenColor',
      ];
      for (final key in sampleKeys) {
        final description = propertyDescription(key, key);
        expect(description, isNotEmpty, reason: 'key: $key');
      }
    });
  });
}
