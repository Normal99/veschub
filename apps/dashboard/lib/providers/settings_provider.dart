/// Riverpod provider for the persisted [SettingsService] in the dashboard app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

/// Asynchronously-created [SettingsService].
final settingsServiceProvider =
    FutureProvider<SettingsService>((ref) => createSettingsService());
