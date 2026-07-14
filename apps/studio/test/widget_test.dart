import 'package:flutter_test/flutter_test.dart';

import 'package:studio/main.dart';

void main() {
  testWidgets('studio placeholder boots', (tester) async {
    await tester.pumpWidget(const StudioApp());
    expect(find.text('Veschub Studio'), findsOneWidget);
    expect(find.text('Studio editor — Phase 3'), findsOneWidget);
  });
}
