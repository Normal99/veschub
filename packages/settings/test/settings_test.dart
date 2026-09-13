import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings/settings.dart';
import 'package:dashboard_model/dashboard_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService', () {
    test('defaults on first launch', () async {
      final service = await createSettingsService();
      expect(service.capabilityLevel, CapabilityLevel.basic);
      expect(service.themeMode, ThemePreference.system);
      expect(service.transport, TransportPreference.auto);
      expect(service.onboardingDone, isFalse);
      expect(service.canvasHintDismissed, isFalse);
    });

    test('load reads persisted values', () async {
      SharedPreferences.setMockInitialValues({
        'settings.capabilityLevel': 'expert',
        'settings.themeMode': 'dark',
        'settings.transport': 'ble',
        'settings.onboardingDone': true,
      });
      final service = await createSettingsService();
      expect(service.capabilityLevel, CapabilityLevel.expert);
      expect(service.themeMode, ThemePreference.dark);
      expect(service.transport, TransportPreference.ble);
      expect(service.onboardingDone, isTrue);
    });

    test('setters persist and notify listeners', () async {
      final service = await createSettingsService();
      var notified = 0;
      service.addListener(() => notified++);

      await service.setCapabilityLevel(CapabilityLevel.advanced);
      expect(service.capabilityLevel, CapabilityLevel.advanced);
      expect(notified, 1);

      await service.setThemeMode(ThemePreference.light);
      expect(service.themeMode, ThemePreference.light);

      await service.setTransport(TransportPreference.usb);
      expect(service.transport, TransportPreference.usb);

      await service.markOnboardingDone();
      expect(service.onboardingDone, isTrue);

      await service.markCanvasHintDismissed();
      expect(service.canvasHintDismissed, isTrue);

      // A fresh service instance reflects the persisted values.
      final reloaded = await createSettingsService();
      expect(reloaded.capabilityLevel, CapabilityLevel.advanced);
      expect(reloaded.themeMode, ThemePreference.light);
      expect(reloaded.transport, TransportPreference.usb);
      expect(reloaded.onboardingDone, isTrue);
      expect(reloaded.canvasHintDismissed, isTrue);
    });

    test('unknown persisted values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'settings.capabilityLevel': 'nope',
        'settings.themeMode': 'bogus',
        'settings.transport': '??',
      });
      final service = await createSettingsService();
      expect(service.capabilityLevel, CapabilityLevel.basic);
      expect(service.themeMode, ThemePreference.system);
      expect(service.transport, TransportPreference.auto);
    });

    test('custom fonts: empty by default', () async {
      final service = await createSettingsService();
      expect(service.customFonts, isEmpty);
    });

    test('addCustomFont persists, notifies, and survives a reload', () async {
      final service = await createSettingsService();
      var notified = 0;
      service.addListener(() => notified++);

      await service.addCustomFont(
        const CustomFontEntry(family: 'My Font', filePath: '/tmp/my_font.ttf'),
      );
      expect(service.customFonts, hasLength(1));
      expect(service.customFonts.single.family, 'My Font');
      expect(notified, 1);

      final reloaded = await createSettingsService();
      expect(reloaded.customFonts, hasLength(1));
      expect(reloaded.customFonts.single.filePath, '/tmp/my_font.ttf');
    });

    test(
        'addCustomFont with an existing family name replaces it, not duplicates it',
        () async {
      final service = await createSettingsService();
      await service.addCustomFont(
        const CustomFontEntry(family: 'My Font', filePath: '/tmp/v1.ttf'),
      );
      await service.addCustomFont(
        const CustomFontEntry(family: 'My Font', filePath: '/tmp/v2.ttf'),
      );
      expect(service.customFonts, hasLength(1));
      expect(service.customFonts.single.filePath, '/tmp/v2.ttf');
    });

    test('removeCustomFont drops the entry and persists the removal', () async {
      final service = await createSettingsService();
      await service.addCustomFont(
        const CustomFontEntry(family: 'My Font', filePath: '/tmp/my_font.ttf'),
      );
      await service.removeCustomFont('My Font');
      expect(service.customFonts, isEmpty);

      final reloaded = await createSettingsService();
      expect(reloaded.customFonts, isEmpty);
    });
  });
}
