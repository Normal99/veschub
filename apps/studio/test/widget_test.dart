import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studio/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'settings.onboardingDone': true,
      'settings.capabilityLevel': 'advanced',
    });
  });

  testWidgets('studio editor boots in Canvas mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();

    expect(find.text('Veschub Studio'), findsOneWidget);
    expect(find.text('Canvas'), findsWidgets);
    expect(find.text('Widgets'), findsOneWidget);
    // No selection on boot -> the inspector shows the placeholder.
    expect(find.text('Select a widget to edit its properties'), findsOneWidget);
  });

  testWidgets('onboarding flips to the editor when completed', (tester) async {
    // First run: onboarding not yet completed.
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Veschub Studio'), findsOneWidget);

    // Completing onboarding marks the pref; the reactive provider must swap
    // home to the editor (regression guard for the FutureProvider reactivity
    // bug where the gate never flipped).
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Veschub Studio'), findsNothing);
    expect(find.text('Veschub Studio'), findsOneWidget);
  });
}
