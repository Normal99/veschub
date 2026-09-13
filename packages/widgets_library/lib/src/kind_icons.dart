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
      _ => Icons.widgets,
    };
