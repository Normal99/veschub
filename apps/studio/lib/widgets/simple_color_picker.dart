/// A shared, simple swatch-based colour picker used by the studio's inspector
/// and template-tweak panel. Kept in one place so the palette never drifts.
library;

import 'package:flutter/material.dart';

/// Curated brand swatch palette for dashboards.
const List<int> kSwatchPalette = [
  0xFF4FC3F7,
  0xFFFFB74D,
  0xFFAED581,
  0xFFEF5350,
  0xFFCE93D8,
  0xFFFFD54F,
  0xFF80CBC4,
  0xFFFFFFFF,
  0xFF000000,
];

/// A swatch-grid colour picker dialog. Returns the chosen ARGB int or null.
class SimpleColorPicker extends StatelessWidget {
  final int current;
  const SimpleColorPicker({required this.current, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Pick a colour'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final c in kSwatchPalette)
            GestureDetector(
              onTap: () => Navigator.of(context).pop(c),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(c),
                  shape: BoxShape.circle,
                  border: c == current
                      ? Border.all(
                          color: Theme.of(context).colorScheme.onSurface,
                          width: 3,
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
