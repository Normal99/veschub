/// Mobile/desktop web-embed implementation backed by `flutter_inappwebview`.
///
/// Used on Android, iOS, Linux, macOS, Windows. Falls back to the stub on
/// platforms where the WebView cannot initialise (e.g. headless tests).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Widget buildWebEmbed({
  required String url,
  bool jsEnabled = true,
}) {
  return InAppWebView(
    initialUrlRequest: URLRequest(url: WebUri(url)),
    initialSettings: InAppWebViewSettings(
      javaScriptEnabled: jsEnabled,
      transparentBackground: true,
    ),
  );
}
