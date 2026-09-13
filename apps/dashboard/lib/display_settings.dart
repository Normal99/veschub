/// Display-mode preferences local to the dashboard viewer app — kiosk-style
/// settings for a permanently-mounted display (a Pi, an old phone taped to
/// the dash) rather than something Studio would ever need to know about,
/// which is why these live here instead of in `packages/settings`.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Persisted, observable display-mode settings for the dashboard viewer.
class DisplaySettings extends ChangeNotifier {
  static const _keyKeepAwake = 'display.keepScreenAwake';
  static const _keyImmersive = 'display.immersiveFullscreen';

  SharedPreferences? _prefs;

  // Defaults favour a mounted/kiosk display: don't let the screen sleep
  // mid-drive, but leave the OS status/nav bars alone until the user
  // deliberately opts into hiding them (immersive mode can make a device
  // awkward to get out of if a user doesn't know the gesture to reveal them
  // again, so it should be an explicit choice, not a surprise default).
  bool _keepScreenAwake = true;
  bool _immersiveFullscreen = false;

  bool get keepScreenAwake => _keepScreenAwake;
  bool get immersiveFullscreen => _immersiveFullscreen;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _keepScreenAwake = _prefs!.getBool(_keyKeepAwake) ?? true;
    _immersiveFullscreen = _prefs!.getBool(_keyImmersive) ?? false;
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool v) async {
    _keepScreenAwake = v;
    await _prefs?.setBool(_keyKeepAwake, v);
    notifyListeners();
    await _applyWakelock();
  }

  Future<void> setImmersiveFullscreen(bool v) async {
    _immersiveFullscreen = v;
    await _prefs?.setBool(_keyImmersive, v);
    notifyListeners();
  }

  /// Applies the current [keepScreenAwake] preference to the real OS
  /// wakelock. Called once on viewer start and again whenever the setting
  /// changes; safe to call redundantly (wakelock_plus no-ops if already in
  /// the requested state). Swallows errors: a platform with no wakelock
  /// channel registered (a test environment, or a platform this plugin
  /// doesn't support) shouldn't crash a settings toggle over it.
  Future<void> _applyWakelock() async {
    try {
      if (_keepScreenAwake) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (_) {
      // No-op: see doc comment above.
    }
  }

  /// Call once when the viewer mounts, after [load] — separate from the
  /// setters so a fresh launch actually engages the wakelock instead of
  /// only doing so the first time the user toggles the setting.
  Future<void> applyOnStart() => _applyWakelock();
}

final displaySettingsProvider = ChangeNotifierProvider<DisplaySettings>((ref) {
  final service = DisplaySettings();
  service.load().then((_) => service.applyOnStart());
  return service;
});
