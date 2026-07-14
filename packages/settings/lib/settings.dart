/// Persisted user settings shared by the studio and dashboard apps.
///
/// Wraps `shared_preferences` in a [ChangeNotifier] so Riverpod/the UI can
/// react to changes. Settings are intentionally small and app-agnostic: the
/// default capability level, the theme mode, and the preferred connection
/// transport. App-specific preferences belong in the app, not here.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard_model/dashboard_model.dart';

/// Preferred connection transport for the dashboard runtime.
enum TransportPreference { ble, usb, auto }

/// Theme mode preference (mirrors Flutter's [ThemeMode] but serialisable by
/// name so the settings package does not depend on material).
enum ThemePreference { system, light, dark }

/// Persisted, observable user settings.
class SettingsService extends ChangeNotifier {
  SettingsService._(this._prefs);

  static const _keyCapability = 'settings.capabilityLevel';
  static const _keyTheme = 'settings.themeMode';
  static const _keyTransport = 'settings.transport';
  static const _keyOnboardingDone = 'settings.onboardingDone';

  final SharedPreferences _prefs;

  CapabilityLevel _capability = CapabilityLevel.basic;
  ThemePreference _theme = ThemePreference.system;
  TransportPreference _transport = TransportPreference.auto;
  bool _onboardingDone = false;

  /// Default capability level shown on first launch of the studio.
  CapabilityLevel get capabilityLevel => _capability;

  /// Theme mode preference.
  ThemePreference get themeMode => _theme;

  /// Preferred connection transport for the dashboard runtime.
  TransportPreference get transport => _transport;

  /// Whether first-run onboarding has been completed.
  bool get onboardingDone => _onboardingDone;

  /// Loads persisted values. Call once at startup, before reading any field.
  Future<void> load() async {
    _capability = _decodeCapability(_prefs.getString(_keyCapability));
    _theme = _decodeTheme(_prefs.getString(_keyTheme));
    _transport = _decodeTransport(_prefs.getString(_keyTransport));
    _onboardingDone = _prefs.getBool(_keyOnboardingDone) ?? false;
    notifyListeners();
  }

  Future<void> setCapabilityLevel(CapabilityLevel level) async {
    _capability = level;
    await _prefs.setString(_keyCapability, level.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemePreference mode) async {
    _theme = mode;
    await _prefs.setString(_keyTheme, mode.name);
    notifyListeners();
  }

  Future<void> setTransport(TransportPreference t) async {
    _transport = t;
    await _prefs.setString(_keyTransport, t.name);
    notifyListeners();
  }

  Future<void> markOnboardingDone() async {
    _onboardingDone = true;
    await _prefs.setBool(_keyOnboardingDone, true);
    notifyListeners();
  }

  static CapabilityLevel _decodeCapability(String? raw) {
    if (raw == null) return CapabilityLevel.basic;
    for (final l in CapabilityLevel.values) {
      if (l.name == raw) return l;
    }
    return CapabilityLevel.basic;
  }

  static ThemePreference _decodeTheme(String? raw) {
    if (raw == null) return ThemePreference.system;
    for (final t in ThemePreference.values) {
      if (t.name == raw) return t;
    }
    return ThemePreference.system;
  }

  static TransportPreference _decodeTransport(String? raw) {
    if (raw == null) return TransportPreference.auto;
    for (final t in TransportPreference.values) {
      if (t.name == raw) return t;
    }
    return TransportPreference.auto;
  }
}

/// Constructs a [SettingsService] bound to the shared preferences instance.
Future<SettingsService> createSettingsService() async {
  final prefs = await SharedPreferences.getInstance();
  final service = SettingsService._(prefs);
  await service.load();
  return service;
}
