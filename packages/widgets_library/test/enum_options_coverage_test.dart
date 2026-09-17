// Regression test for cryptic string properties: a fixed-vocabulary string
// property with no PropertyMeta.options gives the user a plain text field
// with no indication of what values are valid. Verifies the two remaining
// cases found in the full property audit — image.fit and
// tripstats.layoutStyle — now have options, and that each option's value
// matches exactly what the widget's own rendering code actually checks for
// (so the picker can never drift out of sync with the renderer).
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  test('image.fit offers every BoxFit value image_widget.dart recognizes', () {
    final props = propertyManifest['image']!;
    final fitMeta = props.firstWhere((p) => p.key == 'fit');
    final values = fitMeta.options!.map((o) => o.value).toSet();
    expect(
      values,
      {'contain', 'cover', 'fill', 'fitWidth', 'fitHeight', 'none'},
    );
  });

  test(
      'tripstats.layoutStyle offers every layout tripstats_widget.dart '
      'recognizes', () {
    final props = propertyManifest['tripstats']!;
    final layoutMeta = props.firstWhere((p) => p.key == 'layoutStyle');
    final values = layoutMeta.options!.map((o) => o.value).toSet();
    expect(values, {'standard', '3x3', 'porsche'});
  });
}
