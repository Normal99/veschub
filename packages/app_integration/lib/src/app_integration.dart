/// App-to-app integration abstraction.
///
/// Provides a uniform interface for:
///  * launching external apps / URLs ([AppLauncher]),
///  * sharing text/data to other apps ([ShareSheet]),
///  * receiving inbound deep links / App Links / share intents ([DeepLinkReceiver]).
///
/// A default stub implementation is used in tests and on platforms where the
/// native channels are unavailable; the dashboard app injects the real
/// platform implementation at startup.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Launches an external app or URL.
abstract class AppLauncher {
  /// Opens [uri] in the system handler. Returns true if successful.
  Future<bool> launch(String uri);

  /// Launches an app by Android package or iOS URL scheme with optional
  /// [extras] (Android) / query params. Returns true if the app was found.
  Future<bool> launchApp({
    required String packageOrScheme,
    Map<String, String> extras = const {},
  });
}

/// Shares text or a file to other apps via the system share sheet.
abstract class ShareSheet {
  Future<void> shareText(String text, {String? subject});
}

/// Emits inbound deep links / App Links / share intents received by the app.
abstract class DeepLinkReceiver {
  /// The URI that launched the app (null if cold-started normally).
  Future<Uri?> get initialLink;

  /// A broadcast stream of subsequent inbound links.
  Stream<Uri> get links;
}

/// A no-op implementation used in tests and on unsupported platforms.
class StubAppIntegration implements AppLauncher, ShareSheet, DeepLinkReceiver {
  const StubAppIntegration();

  @override
  Future<bool> launch(String uri) async => false;

  @override
  Future<bool> launchApp({
    required String packageOrScheme,
    Map<String, String> extras = const {},
  }) async =>
      false;

  @override
  Future<void> shareText(String text, {String? subject}) async {}

  @override
  Future<Uri?> get initialLink async => null;

  @override
  Stream<Uri> get links => const Stream.empty();
}

/// Method-channel-based implementation for Android/iOS.
///
/// Uses `url_launcher` for URLs and a custom platform channel
/// (`com.veschub.app_integration`) for app launches with extras, share
/// intents, and deep-link reception.
class PlatformAppIntegration
    implements AppLauncher, ShareSheet, DeepLinkReceiver {
  PlatformAppIntegration()
      : _channel = const MethodChannel('com.veschub.app_integration');

  @visibleForTesting
  PlatformAppIntegration.withChannel(this._channel);

  final MethodChannel _channel;
  final StreamController<Uri> _linkController =
      StreamController<Uri>.broadcast();
  Uri? _initial;
  bool _initialised = false;
  Future<void>? _initFuture;

  Future<void> _ensureInit() {
    if (_initialised) return Future<void>.value();
    _initialised = true;
    _initFuture = _doInit();
    return _initFuture!;
  }

  Future<void> _doInit() async {
    _channel.setMethodCallHandler(_handle);
    try {
      final raw = await _channel.invokeMethod<String>('getInitialLink');
      if (raw != null) _initial = Uri.parse(raw);
    } on Exception {
      // Channel not implemented on this platform — no-op.
    }
  }

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case 'onLink':
        final raw = call.arguments as String?;
        if (raw != null) _linkController.add(Uri.parse(raw));
    }
  }

  @override
  Future<bool> launch(String uri) async {
    await _ensureInit();
    try {
      final raw = await _channel.invokeMethod<bool>('launch', {'uri': uri});
      return raw ?? false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<bool> launchApp({
    required String packageOrScheme,
    Map<String, String> extras = const {},
  }) async {
    await _ensureInit();
    try {
      final raw = await _channel.invokeMethod<bool>('launchApp', {
        'target': packageOrScheme,
        'extras': extras,
      });
      return raw ?? false;
    } on Exception {
      return false;
    }
  }

  @override
  Future<void> shareText(String text, {String? subject}) async {
    await _ensureInit();
    try {
      await _channel.invokeMethod<void>('share', {
        'text': text,
        if (subject != null) 'subject': subject,
      });
    } on Exception {
      // Channel not implemented on this platform.
    }
  }

  @override
  Future<Uri?> get initialLink async {
    await _ensureInit();
    return _initial;
  }

  /// Stream of inbound links. Callers that need the initial link delivered
  /// as part of this stream should [await] [initialLink] first, or await
  /// [_initFuture] before subscribing.
  @override
  Stream<Uri> get links {
    _initFuture = _ensureInit();
    return _linkController.stream;
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _linkController.close();
  }
}
