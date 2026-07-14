/// Riverpod provider for the persisted [SettingsService] in the dashboard app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

/// Reactively-observed [SettingsService]. Loads from `shared_preferences` on
/// first read; consumers rebuild when any setter notifies.
final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  final service = SettingsService();
  service.load();
  return service;
});
