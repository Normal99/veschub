import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';

void main() {
  testWidgets('studio editor boots in Canvas mode', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: StudioApp()));
    await tester.pumpAndSettle();

    expect(find.text('Veschub Studio'), findsOneWidget);
    expect(find.text('Canvas'), findsWidgets);
    expect(find.text('Widgets'), findsOneWidget);
    // No selection on boot -> the inspector shows the placeholder.
    expect(find.text('Select a widget to edit its properties'), findsOneWidget);
  });
}
