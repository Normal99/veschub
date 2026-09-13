/// Persisted user settings shared by the studio and dashboard apps.
///
/// Wraps `shared_preferences` in a [ChangeNotifier] so Riverpod/the UI can
/// react to changes. Settings are intentionally small and app-agnostic: the
/// default capability level, the theme mode, and the preferred connection
/// transport. App-specific preferences belong in the app, not here.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard_model/dashboard_model.dart';

/// Preferred connection transport for the dashboard runtime.
enum TransportPreference { ble, usb, auto }

/// A user-imported custom font: [family] is both the display label and the
/// runtime font-family name it was registered under (via `FontLoader`,
/// which lives in the app layer — this package only persists the reference).
/// [filePath] points at the app's own copy of the font file (imports are
/// copied out of wherever the user picked them from, since that original
/// location isn't guaranteed to still exist on a later launch).
class CustomFontEntry {
  final String family;
  final String filePath;
  const CustomFontEntry({required this.family, required this.filePath});

  Map<String, dynamic> toJson() => {'family': family, 'filePath': filePath};

  factory CustomFontEntry.fromJson(Map<String, dynamic> json) =>
      CustomFontEntry(
        family: json['family'] as String,
        filePath: json['filePath'] as String,
      );
}

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
  static const _keyCustomFonts = 'settings.customFonts';

  SharedPreferences? _prefs;

  CapabilityLevel _capability = CapabilityLevel.basic;
  ThemePreference _theme = ThemePreference.system;
  TransportPreference _transport = TransportPreference.auto;
  bool _onboardingDone = false;
  bool _canvasHintDismissed = false;
  bool _autoConnect = true;
  int _dataRate = 10;
  List<CustomFontEntry> _customFonts = [];

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

  /// User-imported custom fonts, available alongside the bundled font
  /// choices. Persisted here (not app-specific) so a dashboard built in
  /// Studio using a custom font still has that font available if opened in
  /// the dashboard viewer on the same machine — the app layer is
  /// responsible for actually registering these with `FontLoader` at
  /// startup and for the import/file-copy workflow itself; this class only
  /// persists the family-name/file-path reference.
  List<CustomFontEntry> get customFonts => List.unmodifiable(_customFonts);

  /// Loads persisted values from `shared_preferences`. Safe to call from a
  /// provider's create function: returns a [Future] that resolves after the
  /// values are read, then notifies listeners so dependents rebuild.
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _capability = _decodeCapability(_prefs!.getString(_keyCapability));
    _theme = _decodeTheme(_prefs!.getString(_keyTheme));
    _transport = _decodeTransport(_prefs!.getString(_keyTransport));
    _onboardingDone = _prefs!.getBool(_keyOnboardingDone) ?? false;
    _canvasHintDismissed = _prefs!.getBool(_keyCanvasHintDismissed) ?? false;
    _autoConnect = _prefs!.getBool(_keyAutoConnect) ?? true;
    _dataRate = _prefs!.getInt(_keyDataRate) ?? 10;
    if (_dataRate < 5 || _dataRate > 50) _dataRate = 10;
    _customFonts = (_prefs!.getStringList(_keyCustomFonts) ?? [])
        .map((raw) =>
            CustomFontEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
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

  /// Adds a custom font entry. The caller has already copied the font file
  /// to a persistent location and (if it wants the font usable without a
  /// restart) registered it with `FontLoader` — this only persists the
  /// reference. Replaces any existing entry with the same [family].
  Future<void> addCustomFont(CustomFontEntry entry) async {
    _customFonts = [
      ..._customFonts.where((f) => f.family != entry.family),
      entry,
    ];
    await _persistCustomFonts();
    notifyListeners();
  }

  /// Removes a custom font entry by family name. Does not delete the
  /// underlying file or un-register the font from the running session
  /// (Flutter's `FontLoader` has no unregister API) — the caller may want
  /// to delete the file itself; the font simply stops being offered as a
  /// choice from here on.
  Future<void> removeCustomFont(String family) async {
    _customFonts = _customFonts.where((f) => f.family != family).toList();
    await _persistCustomFonts();
    notifyListeners();
  }

  Future<void> _persistCustomFonts() async {
    await _prefs?.setStringList(
      _keyCustomFonts,
      _customFonts.map((f) => jsonEncode(f.toJson())).toList(),
    );
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

/// Registers a single custom font with Flutter's [FontLoader] so text using
/// [family] actually picks it up. A no-op (not an error) if [filePath] no
/// longer exists — a dashboard referencing a since-deleted custom font
/// should still open, just falling back to the ambient theme font for that
/// property, same as any other unrecognised `fontFamily` value.
Future<void> registerCustomFont(String family, String filePath) async {
  final file = File(filePath);
  if (!file.existsSync()) return;
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future.value(bytes.buffer.asByteData()));
  await loader.load();
}

/// Registers every already-imported custom font from [settings]. Call once
/// at startup, after [SettingsService.load] — registration doesn't persist
/// across process restarts, unlike the reference itself. Both the studio
/// (where fonts are imported) and the dashboard viewer (which must render
/// the same fonts a dashboard was built with) call this.
Future<void> registerAllCustomFonts(SettingsService settings) async {
  for (final entry in settings.customFonts) {
    await registerCustomFont(entry.family, entry.filePath);
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
