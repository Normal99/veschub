/// The font choices actually offered by the inspector's font picker: the
/// bundled catalogue (`kFontChoices`, in `widgets_library` — no Riverpod
/// dependency there) plus whatever the user has imported this session,
/// reactively kept in sync with [SettingsService.customFonts].
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';
import 'package:widgets_library/widgets_library.dart';

final fontChoicesProvider = Provider<List<FontChoice>>((ref) {
  final settings = ref.watch(settingsServiceProvider);
  return [
    ...kFontChoices,
    for (final custom in settings.customFonts)
      FontChoice(label: custom.family, fontFamily: custom.family),
  ];
});
