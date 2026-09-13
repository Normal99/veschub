// Golden-screenshot regression tests for the 9 curated example dashboards
// (Tesla, Porsche, BMW, Audi, VW, Ford, CarPlay, Android Auto, VESC Mobile)
// — the ones that took many iterations to get looking right during the
// AIdashboards push. Locks them in as visual baselines so a future widget
// or property-manifest refactor can't silently regress their look; a
// mismatch here means "go look at what changed," not necessarily "revert
// it," but it should never pass unnoticed.
//
// Uses the same rendering pipeline as the standalone dashboard_renderer
// tool (DashboardRenderer widget, mock telemetry) so goldens reflect
// exactly what that tool — and the real dashboard app — would draw.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_renderer/main.dart';

const _examples = [
  'android_auto',
  'audi_virtual_cockpit',
  'bmw_classic',
  'carplay',
  'ford_digital',
  'porsche_taycan',
  'tesla_model3',
  'vesc_mobile',
  'vw_digital',
];

void main() {
  for (final name in _examples) {
    testWidgets('$name renders unchanged from its golden baseline',
        (tester) async {
      tester.view.physicalSize = const Size(2000, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // The whole load-and-settle sequence must run inside one runAsync:
      // DashboardRenderer loads its document via real dart:io File I/O in
      // initState, and flutter_test's default fake-async zone never lets
      // that complete no matter how much you pump — it just sits on
      // "Loading..." forever (confirmed directly: pumping 5+ frames plus
      // pumpAndSettle left the status text unchanged; wrapping the same
      // wait in runAsync AFTER pumpWidget also didn't help, since the
      // File.exists()/readAsString() calls were already stuck, having
      // started inside the fake-async zone from initState). Starting
      // pumpWidget itself inside runAsync is what actually fixes it.
      await tester.runAsync(() async {
        await tester.pumpWidget(DashboardRendererApp(
          dashboardPath: '../../examples/$name.veschub.json',
        ));
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(DashboardRendererApp),
        matchesGoldenFile('goldens/$name.png'),
      );
    });
  }
}
