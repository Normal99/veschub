import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard/display_settings.dart';
import 'package:dashboard/settings/dashboard_settings_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: DashboardSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Keep screen awake defaults on, Immersive fullscreen defaults off',
      (tester) async {
    await pumpSettings(tester);

    final keepAwake = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Keep screen awake'),
    );
    final immersive = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Immersive fullscreen'),
    );
    expect(keepAwake.value, isTrue);
    expect(immersive.value, isFalse);
  });

  testWidgets('toggling Immersive fullscreen updates DisplaySettings',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Immersive fullscreen'));
    await tester.pumpAndSettle();

    final immersive = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Immersive fullscreen'),
    );
    expect(immersive.value, isTrue);

    final element = tester.element(find.byType(DashboardSettingsScreen));
    final settings = ProviderScope.containerOf(element).read(displaySettingsProvider);
    expect(settings.immersiveFullscreen, isTrue);
  });
}
