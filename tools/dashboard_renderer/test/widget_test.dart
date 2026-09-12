import 'package:flutter_test/flutter_test.dart';
import 'package:dashboard_renderer/main.dart';

void main() {
  testWidgets('DashboardRendererApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const DashboardRendererApp());
    expect(find.byType(DashboardRendererApp), findsOneWidget);
  });
}
