/// Stub web-embed implementation for platforms without `flutter_inappwebview`
/// (Flutter web, unit tests). Renders an informative placeholder.
library;

import 'package:flutter/material.dart';

import '../src/theme.dart';

Widget buildWebEmbed({
  required String url,
  bool jsEnabled = true,
}) {
  return Builder(
    builder: (context) {
      final theme = DashboardThemeProvider.of(context);
      return Container(
        decoration: BoxDecoration(
          color: theme.background.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.secondary.withValues(alpha: 0.3)),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, color: theme.accent, size: 32),
            const SizedBox(height: 8),
            Text(
              url,
              style: TextStyle(color: theme.accent, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Web embedding unavailable on this platform',
              style: TextStyle(color: theme.secondary, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  );
}
