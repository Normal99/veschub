import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dashboard/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
    });
  });

  testWidgets('dashboard app boots and renders the sim viewer', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DashboardApp()));

    // Let the async SettingsService resolve before the viewer mounts.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // App chrome renders once the viewer is up.
    expect(find.text('Veschub · Sim viewer'), findsOneWidget);

    // The runtime's first dirty emit (with literal bindings resolved) lands on
    // a subsequent frame. Pump a few frames (not pumpAndSettle — the sim's
    // periodic timer would time that out) so the bound widget labels appear.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Literal-bound labels from the sample document are now resolved.
    expect(find.text('RPM'), findsOneWidget);
    expect(find.text('Pack voltage'), findsOneWidget);
  });
}
