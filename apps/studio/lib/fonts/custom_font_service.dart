/// The Studio-side half of custom fonts: the file-picker import workflow
/// and removal. Runtime registration (`FontLoader`) and the persisted
/// family-name/file-path reference both live in `packages/settings` — see
/// `registerCustomFont`/`registerAllCustomFonts`/`CustomFontEntry` there —
/// since the dashboard viewer app needs those too, to render a dashboard
/// with the same fonts it was built with, but has no need for the import UI
/// itself.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:settings/settings.dart';

/// Opens a file picker for a `.ttf`/`.otf` file, copies it into the app's
/// own support directory (the original picked location isn't guaranteed to
/// still exist on a later launch), registers it immediately via
/// [registerCustomFont] so it's usable without restarting, and persists the
/// reference. Returns the new family name, or null if the user cancelled.
///
/// The family name is derived from the file's own name (so "Good Times.ttf"
/// becomes "Good Times"); a collision with an existing custom font of the
/// same name overwrites that entry (matching how re-importing a same-named
/// dashboard file already behaves elsewhere in Studio) rather than silently
/// making a second, indistinguishable entry.
Future<String?> importCustomFont(SettingsService settings) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['ttf', 'otf'],
    allowMultiple: false,
  );
  final picked = result?.files.single;
  if (picked?.path == null) return null;

  final sourcePath = picked!.path!;
  final ext = sourcePath.split('.').last.toLowerCase();
  final baseName = picked.name
      .replaceAll(RegExp(r'\.(ttf|otf)$', caseSensitive: false), '')
      .trim();
  final family = baseName.isEmpty ? 'Custom Font' : baseName;

  final supportDir = await getApplicationSupportDirectory();
  final fontsDir = Directory('${supportDir.path}/custom_fonts');
  if (!fontsDir.existsSync()) fontsDir.createSync(recursive: true);
  final destPath = '${fontsDir.path}/$family.$ext';
  await File(sourcePath).copy(destPath);

  await registerCustomFont(family, destPath);
  await settings
      .addCustomFont(CustomFontEntry(family: family, filePath: destPath));
  return family;
}

/// Removes a custom font: deletes its persistent copy on disk (best-effort
/// — a missing file is not an error) and drops the settings reference. The
/// font stays usable for the rest of this session (Flutter's `FontLoader`
/// has no unregister call) but won't be offered as a choice or reloaded on
/// the next launch.
Future<void> removeCustomFont(
    SettingsService settings, CustomFontEntry entry) async {
  try {
    final file = File(entry.filePath);
    if (file.existsSync()) file.deleteSync();
  } catch (_) {
    // Best-effort: an already-missing or unwritable file shouldn't block
    // removing the reference itself.
  }
  await settings.removeCustomFont(entry.family);
}
