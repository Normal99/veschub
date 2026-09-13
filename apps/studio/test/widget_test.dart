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

  testWidgets('studio editor boots in Template mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();

    expect(find.text('Veschub Studio'), findsOneWidget);
    // Fresh launch lands on the Template gallery, not a blank canvas — a
    // friendlier default for a first-time user (see editorModeProvider).
    expect(find.text('Choose a starter dashboard'), findsOneWidget);
  });

  testWidgets('switching to Canvas mode shows the palette and empty inspector',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Canvas'));
    await tester.pumpAndSettle();

    expect(find.text('Widgets'), findsOneWidget);
    // No selection on switch -> the inspector shows the placeholder.
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
