import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard/display_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DisplaySettings', () {
    test('defaults favour a mounted/kiosk display', () async {
      final settings = DisplaySettings();
      await settings.load();
      expect(settings.keepScreenAwake, isTrue);
      expect(settings.immersiveFullscreen, isFalse);
    });

    test('load reads persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'display.keepScreenAwake': false,
        'display.immersiveFullscreen': true,
      });
      final settings = DisplaySettings();
      await settings.load();
      expect(settings.keepScreenAwake, isFalse);
      expect(settings.immersiveFullscreen, isTrue);
    });

    test('setters persist, notify listeners, and are visible to a fresh '
        'instance', () async {
      final settings = DisplaySettings();
      await settings.load();
      var notified = 0;
      settings.addListener(() => notified++);

      await settings.setKeepScreenAwake(false);
      expect(settings.keepScreenAwake, isFalse);
      expect(notified, greaterThanOrEqualTo(1));

      await settings.setImmersiveFullscreen(true);
      expect(settings.immersiveFullscreen, isTrue);

      final reloaded = DisplaySettings();
      await reloaded.load();
      expect(reloaded.keepScreenAwake, isFalse);
      expect(reloaded.immersiveFullscreen, isTrue);
    });
  });
}
