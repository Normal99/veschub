/// Riverpod provider for the persisted [SettingsService].
///
/// Initialised asynchronously from `shared_preferences`; the UI watches the
/// [AsyncValue] and shows a loading splash until ready. The capability-level
/// editor provider is seeded from the persisted default on first load.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

/// Asynchronously-created [SettingsService].
final settingsServiceProvider =
    FutureProvider<SettingsService>((ref) => createSettingsService());
