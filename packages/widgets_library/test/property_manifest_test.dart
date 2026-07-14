import 'package:dashboard_model/dashboard_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('visibleProperties', () {
    test('Basic level shows only safe props for gauge', () {
      final visible = visibleProperties('gauge', CapabilityLevel.basic);
      final keys = visible.map((m) => m.key).toSet();
      expect(keys, containsAll(['min', 'max', 'label', 'unit', 'color']));
      expect(keys, isNot(contains('value')));
      expect(keys, isNot(contains('accent')));
    });

    test('Advanced reveals value binding + accent', () {
      final visible = visibleProperties('gauge', CapabilityLevel.advanced);
      final keys = visible.map((m) => m.key).toSet();
      expect(keys, containsAll(['value', 'accent', 'min', 'max']));
    });

    test('Expert includes everything Advanced does', () {
      final advanced = visibleProperties('chart', CapabilityLevel.advanced);
      final expert = visibleProperties('chart', CapabilityLevel.expert);
      final advKeys = advanced.map((m) => m.key).toSet();
      final expKeys = expert.map((m) => m.key).toSet();
      expect(expKeys.containsAll(advKeys), isTrue);
    });

    test('unknown kind returns empty list', () {
      expect(visibleProperties('nonsense', CapabilityLevel.expert), isEmpty);
    });
  });

  group('transformsUnlockedAt', () {
    test('Basic locks transforms', () {
      expect(transformsUnlockedAt(CapabilityLevel.basic), isFalse);
    });

    test('Advanced and Expert unlock transforms', () {
      expect(transformsUnlockedAt(CapabilityLevel.advanced), isTrue);
      expect(transformsUnlockedAt(CapabilityLevel.expert), isTrue);
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
}
