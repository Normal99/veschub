/// Persisted user settings shared by the studio and dashboard apps.
///
/// Wraps `shared_preferences` in a [ChangeNotifier] so Riverpod/the UI can
/// react to changes. Settings are intentionally small and app-agnostic: the
/// default capability level, the theme mode, and the preferred connection
/// transport. App-specific preferences belong in the app, not here.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard_model/dashboard_model.dart';

/// Preferred connection transport for the dashboard runtime.
enum TransportPreference { ble, usb, auto }

/// Theme mode preference (mirrors Flutter's [ThemeMode] but serialisable by
/// name so the settings package does not depend on material).
enum ThemePreference { system, light, dark }

/// Persisted, observable user settings.
class SettingsService extends ChangeNotifier {
  SettingsService();

  static const _keyCapability = 'settings.capabilityLevel';
  static const _keyTheme = 'settings.themeMode';
  static const _keyTransport = 'settings.transport';
  static const _keyOnboardingDone = 'settings.onboardingDone';
  static const _keyCanvasHintDismissed = 'settings.canvasHintDismissed';
  static const _keyAutoConnect = 'settings.autoConnect';
  static const _keyDataRate = 'settings.dataRate';

  SharedPreferences? _prefs;

  CapabilityLevel _capability = CapabilityLevel.basic;
  ThemePreference _theme = ThemePreference.system;
  TransportPreference _transport = TransportPreference.auto;
  bool _onboardingDone = false;
  bool _canvasHintDismissed = false;
  bool _autoConnect = true;
  int _dataRate = 10;

  /// Default capability level shown on first launch of the studio.
  CapabilityLevel get capabilityLevel => _capability;

  /// Theme mode preference.
  ThemePreference get themeMode => _theme;

  /// Preferred connection transport for the dashboard runtime.
  TransportPreference get transport => _transport;

  /// Whether first-run onboarding has been completed.
  bool get onboardingDone => _onboardingDone;

  /// Whether the "drag a widget here" first-time Canvas hint has been
  /// dismissed (either explicitly, or implicitly by dropping a widget).
  bool get canvasHintDismissed => _canvasHintDismissed;

  /// Auto-connect to the preferred transport on app launch.
  bool get autoConnect => _autoConnect;

  /// Maximum telemetry update frequency in Hz (5, 10, 20, or 50).
  int get dataRate => _dataRate;

  /// Loads persisted values from `shared_preferences`. Safe to call from a
  /// provider's create function: returns a [Future] that resolves after the
  /// values are read, then notifies listeners so dependents rebuild.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _capability = _decodeCapability(_prefs!.getString(_keyCapability));
    _theme = _decodeTheme(_prefs!.getString(_keyTheme));
    _transport = _decodeTransport(_prefs!.getString(_keyTransport));
    _onboardingDone = _prefs!.getBool(_keyOnboardingDone) ?? false;
    _canvasHintDismissed =
        _prefs!.getBool(_keyCanvasHintDismissed) ?? false;
    _autoConnect = _prefs!.getBool(_keyAutoConnect) ?? true;
    _dataRate = _prefs!.getInt(_keyDataRate) ?? 10;
    if (_dataRate < 5 || _dataRate > 50) _dataRate = 10;
    notifyListeners();
  }

  Future<void> setCapabilityLevel(CapabilityLevel level) async {
    _capability = level;
    await _prefs?.setString(_keyCapability, level.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemePreference mode) async {
    _theme = mode;
    await _prefs?.setString(_keyTheme, mode.name);
    notifyListeners();
  }

  Future<void> setTransport(TransportPreference t) async {
    _transport = t;
    await _prefs?.setString(_keyTransport, t.name);
    notifyListeners();
  }

  Future<void> markOnboardingDone() async {
    _onboardingDone = true;
    await _prefs?.setBool(_keyOnboardingDone, true);
    notifyListeners();
  }

  Future<void> markCanvasHintDismissed() async {
    _canvasHintDismissed = true;
    await _prefs?.setBool(_keyCanvasHintDismissed, true);
    notifyListeners();
  }

  Future<void> setAutoConnect(bool v) async {
    _autoConnect = v;
    await _prefs?.setBool(_keyAutoConnect, v);
    notifyListeners();
  }

  Future<void> setDataRate(int hz) async {
    _dataRate = hz.clamp(5, 50);
    await _prefs?.setInt(_keyDataRate, _dataRate);
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

/// Constructs a [SettingsService], loads it, and returns the ready instance.
Future<SettingsService> createSettingsService() async {
  final service = SettingsService();
  await service.load();
  return service;
}

/// Reactively-observed [SettingsService]. Loads from `shared_preferences` on
/// first read; consumers rebuild when any setter notifies.
///
/// Shared by the studio and dashboard apps so both observe a single
/// definition; adding `autoDispose`/`keepAlive` semantics here applies to
/// both.
final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  final service = SettingsService();
  service.load();
  return service;
});
