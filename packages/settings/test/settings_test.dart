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
  });
}
