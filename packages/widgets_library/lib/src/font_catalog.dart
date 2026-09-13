/// The catalogue of fonts and weights a widget's `fontFamily`/`fontWeight`
/// properties can be set to, used to drive a searchable picker in the Studio
/// inspector instead of a raw text field. See `theme.dart` for
/// `kDashboardFontFamily`, the app-wide default this catalogue's "Default"
/// entry defers to.
library;

/// One selectable font in the picker: [label] is shown to the user,
/// [fontFamily] is the actual value stored in the property (empty string
/// means "unset" — inherit the ambient theme font rather than override it).
class FontChoice {
  final String label;
  final String fontFamily;
  const FontChoice({required this.label, required this.fontFamily});
}

/// All fonts a widget can select via its `fontFamily` property. "Default"
/// (empty string) always comes first so it reads as the safe/neutral choice.
const List<FontChoice> kFontChoices = [
  FontChoice(label: 'Default', fontFamily: ''),
  FontChoice(
      label: 'Rajdhani', fontFamily: 'packages/widgets_library/Rajdhani'),
  FontChoice(
      label: 'Orbitron', fontFamily: 'packages/widgets_library/Orbitron'),
  FontChoice(
      label: 'Share Tech Mono',
      fontFamily: 'packages/widgets_library/ShareTechMono'),
  FontChoice(
      label: 'Titillium Web',
      fontFamily: 'packages/widgets_library/TitilliumWeb'),
  FontChoice(
      label: 'Barlow Condensed',
      fontFamily: 'packages/widgets_library/BarlowCondensed'),
  FontChoice(label: 'Inter', fontFamily: 'packages/widgets_library/Inter'),
  FontChoice(label: 'Outfit', fontFamily: 'packages/widgets_library/Outfit'),
  FontChoice(label: 'Roboto', fontFamily: 'packages/widgets_library/Roboto'),
  FontChoice(label: 'Manrope', fontFamily: 'packages/widgets_library/Manrope'),
  FontChoice(label: 'Exo 2', fontFamily: 'packages/widgets_library/Exo2'),
  FontChoice(label: 'Sora', fontFamily: 'packages/widgets_library/Sora'),
];

/// One selectable weight in the picker: [label] is shown to the user,
/// [value] is the string `_parseFontWeight` (in `cosmetic_helpers.dart`)
/// accepts.
class FontWeightChoice {
  final String label;
  final String value;
  const FontWeightChoice({required this.label, required this.value});
}

/// All font weights a widget can select via its `fontWeight` property,
/// covering every value `_parseFontWeight` recognises.
const List<FontWeightChoice> kFontWeightChoices = [
  FontWeightChoice(label: 'Thin (100)', value: 'w100'),
  FontWeightChoice(label: 'Extra Light (200)', value: 'w200'),
  FontWeightChoice(label: 'Light (300)', value: 'w300'),
  FontWeightChoice(label: 'Regular (400)', value: 'w400'),
  FontWeightChoice(label: 'Medium (500)', value: 'w500'),
  FontWeightChoice(label: 'Semi Bold (600)', value: 'w600'),
  FontWeightChoice(label: 'Bold (700)', value: 'w700'),
  FontWeightChoice(label: 'Extra Bold (800)', value: 'w800'),
  FontWeightChoice(label: 'Black (900)', value: 'w900'),
];
