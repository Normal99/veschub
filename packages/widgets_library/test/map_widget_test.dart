import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgets_library/widgets_library.dart';

void main() {
  Widget host(Map<String, dynamic> props) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: MapWidget(properties: props),
          ),
        ),
      );

  testWidgets(
      'default mapStyle renders the decorative graphic, not live tiles '
      '(no network involved)', (tester) async {
    await tester.pumpWidget(host({'label': 'Navigation'}));
    await tester.pump();

    expect(find.byType(FlutterMap), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'mapStyle "osm" with no lat/lon bound yet shows a placeholder instead '
      'of attempting to render tiles for a null centre', (tester) async {
    await tester.pumpWidget(host({'mapStyle': 'osm'}));
    await tester.pump();

    expect(find.text('No GPS fix yet'), findsOneWidget);
    // Confirms this path never even constructs FlutterMap (and so never
    // attempts a real network tile fetch) when there's no GPS fix.
    expect(find.byType(FlutterMap), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // Deliberately no test exercises mapStyle: 'osm' with a real lat/lon —
  // doing so would construct a real FlutterMap that immediately attempts a
  // genuine network tile fetch from tile.openstreetmap.org in initState,
  // which isn't something this test suite should depend on (network
  // access, OSM rate limits, CI flakiness). That path is verified manually
  // against the live running app instead — see ROADMAP.md.
}
