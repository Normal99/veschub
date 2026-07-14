import 'package:app_integration/app_integration.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StubAppIntegration', () {
    const stub = StubAppIntegration();

    test('launch returns false', () async {
      expect(await stub.launch('https://example.com'), isFalse);
    });

    test('launchApp returns false', () async {
      expect(
        await stub.launchApp(packageOrScheme: 'com.example.app'),
        isFalse,
      );
    });

    test('shareText is a no-op', () async {
      await stub.shareText('hello');
    });

    test('initialLink is null', () async {
      expect(await stub.initialLink, isNull);
    });

    test('links stream is empty', () async {
      final events = await stub.links.toList();
      expect(events, isEmpty);
    });
  });

  group('PlatformAppIntegration', () {
    late List<MethodCall> calls;
    late PlatformAppIntegration integration;

    setUp(() {
      calls = [];
      // Default handler responds true for launch, echoes link for getInitialLink.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.veschub.app_integration'),
        (call) async {
          calls.add(call);
          switch (call.method) {
            case 'getInitialLink':
              return 'veschub://dashboard/42';
            case 'launch':
              return true;
            case 'launchApp':
              return true;
            case 'share':
              return null;
            default:
              return null;
          }
        },
      );
      integration = PlatformAppIntegration();
    });

    tearDown(() {
      integration.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.veschub.app_integration'),
        null,
      );
    });

    test('getInitialLink parses the platform-supplied URI', () async {
      final link = await integration.initialLink;
      expect(link, Uri.parse('veschub://dashboard/42'));
    });

    test('launch calls the channel with the uri', () async {
      final ok = await integration.launch('https://example.com');
      expect(ok, isTrue);
      expect(
        calls,
        contains(
          predicate<MethodCall>(
            (c) =>
                c.method == 'launch' &&
                c.arguments['uri'] == 'https://example.com',
          ),
        ),
      );
    });

    test('launchApp forwards package + extras', () async {
      final ok = await integration.launchApp(
        packageOrScheme: 'com.example.app',
        extras: {'key': 'value'},
      );
      expect(ok, isTrue);
      expect(
        calls,
        contains(
          predicate<MethodCall>(
            (c) =>
                c.method == 'launchApp' &&
                c.arguments['target'] == 'com.example.app' &&
                (c.arguments['extras'] as Map)['key'] == 'value',
          ),
        ),
      );
    });

    test('shareText forwards text + subject', () async {
      await integration.shareText('hello', subject: 'greeting');
      expect(
        calls,
        contains(
          predicate<MethodCall>(
            (c) =>
                c.method == 'share' &&
                c.arguments['text'] == 'hello' &&
                c.arguments['subject'] == 'greeting',
          ),
        ),
      );
    });

    test('onLink events emit on the links stream', () async {
      await integration.initialLink; // ensure handler attached
      final future = integration.links.first;
      // Simulate a native deep-link event.
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.veschub.app_integration',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onLink', 'veschub://dashboard/99'),
        ),
        (data) {},
      );
      final link = await future;
      expect(link, Uri.parse('veschub://dashboard/99'));
    });
  });
}
