/// The canonical icon for each built-in widget kind.
///
/// Single source of truth so the palette, layer panel, and any other UI
/// that lists widget kinds can't drift out of sync or duplicate an icon
/// across two unrelated kinds by accident.
library;

import 'package:flutter/material.dart';

IconData kindIcon(String kind) => switch (kind) {
      'gauge' => Icons.speed,
      'bar' => Icons.bar_chart,
      'text' => Icons.text_fields,
      'chart' => Icons.show_chart,
      'status' => Icons.info_outline,
      'image' => Icons.image,
      'web' => Icons.public,
      'paint' => Icons.brush,
      'digitalspeed' => Icons.numbers,
      'music' => Icons.music_note,
      'tripstats' => Icons.route,
      'power' => Icons.bolt,
      'warnings' => Icons.warning,
      'minigauge' => Icons.tune,
      'appgrid' => Icons.apps,
      'statusbar' => Icons.view_headline,
      'climate' => Icons.thermostat,
      'car_viz' => Icons.directions_car,
      'map' => Icons.map,
      'battery_range' => Icons.battery_charging_full,
      'power_flow' => Icons.sync_alt,
      'gear_selector' => Icons.swap_vert,
      'gps' => Icons.gps_fixed,
      _ => Icons.widgets,
    };

/// A one-line, plain-language description of what a widget kind is for —
/// shown as a tooltip in the Studio palette so a new user can tell what
/// they're about to drag onto the canvas before they drop it.
String kindDescription(String kind) => switch (kind) {
      'gauge' => 'Circular dial for a single value, like RPM or speed.',
      'bar' => 'A fill bar for a value between a min and max, like duty cycle.',
      'text' => 'A plain label and value, with an optional unit.',
      'chart' => 'A scrolling line chart of a value over time.',
      'status' => 'A status readout, like a fault code or connection state.',
      'image' => 'A static image or icon from a file or asset.',
      'web' => 'An embedded web page.',
      'paint' => 'A custom hand-drawn shape via the paint program editor.',
      'digitalspeed' => 'A large digital speed/number readout with a unit.',
      'music' => 'Now-playing media info (title, artist, artwork).',
      'tripstats' => 'A multi-stat trip summary panel (distance, time, etc).',
      'power' => 'A power/wattage readout.',
      'warnings' => 'A list of active warnings or fault conditions.',
      'minigauge' =>
        'A compact arc or bar gauge for a secondary value, with an icon.',
      'appgrid' => 'A grid of app-style shortcut icons.',
      'statusbar' => 'A thin top status strip (clock, signal, battery, etc).',
      'climate' => 'Cabin climate readout (temperature, fan, mode).',
      'car_viz' => 'A top-down car silhouette showing doors/lane status.',
      'map' => 'A live map centred on GPS position.',
      'battery_range' => 'Battery percentage plus estimated remaining range.',
      'power_flow' => 'An animated power-flow diagram (battery/motor/regen).',
      'gear_selector' => 'A P/R/N/D gear-selector indicator.',
      'gps' => 'Speed, altitude, and coordinates in one compact panel.',
      _ => 'A dashboard widget.',
    };
