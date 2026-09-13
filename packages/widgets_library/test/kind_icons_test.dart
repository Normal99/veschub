import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  group('kindDescription', () {
    test('every manifest kind has a real, non-fallback description', () {
      for (final kind in propertyManifest.keys) {
        final description = kindDescription(kind);
        expect(description, isNot('A dashboard widget.'),
            reason: '"$kind" is missing a real kindDescription entry — the '
                'palette tooltip would fall back to a useless generic line.');
        expect(description, isNotEmpty);
      }
    });

    test('unknown kind falls back to a generic description', () {
      expect(kindDescription('not_a_real_kind'), 'A dashboard widget.');
    });
  });
}
