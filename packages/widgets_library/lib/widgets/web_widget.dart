/// Embeds a live web page in a dashboard cell via `flutter_inappwebview`.
///
/// Uses a conditional import to select the platform implementation:
///  * `dart:io` platforms (Android, iOS, Linux, macOS, Windows) →
///    [web_widget_io] backed by `flutter_inappwebview`.
///  * web + tests → [web_widget_stub] (placeholder).
library;

import 'package:dashboard_runtime/dashboard_runtime.dart';
import 'package:flutter/material.dart';

import '../src/theme.dart';
import 'web_widget_stub.dart' if (dart.library.io) 'web_widget_io.dart' as impl;

/// Renders a `web` widget embedding a live web page.
///
/// Resolved properties:
///  * `url`       — page URL (String, required)
///  * `js`        — JavaScript enabled (bool, default true)
///  * `title`     — optional caption (rendered as an overlay header)
class WebWidget extends StatelessWidget {
  final ResolvedProperties properties;

  const WebWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final url = properties['url'] as String? ?? 'about:blank';
    final js = (properties['js'] as bool?) ?? true;
    final title = properties['title'] as String?;
    final borderRadiusRaw = (properties['borderRadius'] as num?) ?? 8.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadiusRaw.toDouble()),
      child: Stack(
        children: [
          Positioned.fill(
            child: impl.buildWebEmbed(url: url, jsEnabled: js),
          ),
          if (title != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TitleBar(title: title),
            ),
        ],
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  final String title;
  const _TitleBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = DashboardThemeProvider.of(context);
    return Container(
      color: theme.background.withValues(alpha: 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title,
        style: TextStyle(color: theme.foreground, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
