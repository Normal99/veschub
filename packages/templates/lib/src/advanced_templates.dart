/// Advanced example dashboard templates sourced from the repo examples/ directory.
///
/// Each template is a full-featured dashboard (Tesla, Porsche, BMW, Audi, etc.)
/// with no editable knobs — users explore these as references and switch to
/// Canvas mode for editing.
library;

import 'dart:convert';

import 'package:dashboard_model/dashboard_model.dart';

DashboardTemplate _makeAdvancedTemplate({
  required String id,
  required String name,
  required String description,
  required String json,
}) {
  final map = jsonDecode(json) as Map<String, dynamic>;
  final migrated = migrate(map);
  return DashboardTemplate(
    id: id,
    name: name,
    description: description,
    category: 'Advanced Dashboard Templates',
    level: CapabilityLevel.advanced,
    document: DashboardDocument.fromJson(migrated),
    knobs: const [],
  );
}

final advancedDashboardTemplates = <DashboardTemplate>[
  _makeAdvancedTemplate(
    id: 'tesla-model3',
    name: 'Tesla Model 3',
    description:
        'Tesla-inspired minimalist dashboard with centered speedometer, car viz, trip stats, and battery info.',
    json: r'''{
  "version": 2,
  "name": "Tesla Model 3",
  "description": "Tesla-inspired minimalist dashboard with centered speedometer",
  "canvas": {"width": 1920.0, "height": 1080.0},
  "widgets": [
    {
      "id": "speedometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 480, 50],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "speed"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 320},
        "label": {"type": "literal", "value": ""},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4286611584},
        "tickCount": {"type": "literal", "value": 16},
        "sweepAngle": {"type": "literal", "value": 360},
        "startAngle": {"type": "literal", "value": 270},
        "arcWidth": {"type": "literal", "value": 4},
        "needleStyle": {"type": "literal", "value": "none"},
        "showCenterText": {"type": "literal", "value": true},
        "centerValue": {"type": "telemetry", "key": "speed"},
        "centerUnit": {"type": "literal", "value": "km/h"},
        "showTickLabels": {"type": "literal", "value": true},
        "backgroundColor": {"type": "literal", "value": 0},
        "borderRadius": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 360},
        "padding": {"type": "literal", "value": 120},
        "width": {"type": "literal", "value": 1000},
        "height": {"type": "literal", "value": 900},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Inter"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": -0.5}
      },
      "level": "basic"
    },
    {
      "id": "odometer",
      "kind": "text",
      "transform": [1, 0, 0, 1, 900, 780],
      "z": 11,
      "properties": {
        "value": {"type": "telemetry", "key": "odometer"},
        "unit": {"type": "literal", "value": "km"},
        "fontSize": {"type": "literal", "value": 36},
        "color": {"type": "literal", "value": 4286611584},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 200},
        "height": {"type": "literal", "value": 60},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Inter"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": -0.5}
      },
      "level": "basic"
    },
    {
      "id": "power_bar",
      "kind": "power_flow",
      "transform": [1, 0, 0, 1, 1200, 380],
      "z": 12,
      "properties": {
        "power": {"type": "telemetry", "key": "power"},
        "maxPower": {"type": "literal", "value": 100},
        "color": {"type": "literal", "value": 4294940672},
        "accent": {"type": "literal", "value": 4286611584},
        "label": {"type": "literal", "value": "kW"},
        "barWidth": {"type": "literal", "value": 120},
        "barHeight": {"type": "literal", "value": 8},
        "fontSize": {"type": "literal", "value": 20},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 220},
        "height": {"type": "literal", "value": 50}
      },
      "level": "basic"
    },
    {
      "id": "car_viz",
      "kind": "car_viz",
      "transform": [1, 0, 0, 1, 100, 250],
      "z": 5,
      "properties": {
        "doorLeft": {"type": "literal", "value": false},
        "doorRight": {"type": "literal", "value": false},
        "laneLeft": {"type": "literal", "value": false},
        "laneRight": {"type": "literal", "value": false},
        "carAhead": {"type": "literal", "value": false},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4286611584},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 400},
        "height": {"type": "literal", "value": 450}
      },
      "level": "basic"
    },
    {
      "id": "trip_stats",
      "kind": "tripstats",
      "transform": [1, 0, 0, 1, 1450, 150],
      "z": 5,
      "properties": {
        "label1": {"type": "literal", "value": "Since 10:49"},
        "value1": {"type": "telemetry", "key": "trip_distance"},
        "unit1": {"type": "literal", "value": "km"},
        "label2": {"type": "literal", "value": "Since last charge"},
        "value2": {"type": "telemetry", "key": "energy_used"},
        "unit2": {"type": "literal", "value": "kWh"},
        "label3": {"type": "literal", "value": "Monthly"},
        "value3": {"type": "telemetry", "key": "avg_speed"},
        "unit3": {"type": "literal", "value": "km/h"},
        "label4": {"type": "literal", "value": ""},
        "value4": {"type": "literal", "value": 0},
        "unit4": {"type": "literal", "value": ""},
        "columns": {"type": "literal", "value": 1},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4286611584},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 40},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 450},
        "height": {"type": "literal", "value": 450},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Inter"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": -0.5}
      },
      "level": "basic"
    },
    {
      "id": "battery_range",
      "kind": "battery_range",
      "transform": [1, 0, 0, 1, 100, 850],
      "z": 15,
      "properties": {
        "batteryLevel": {"type": "literal", "value": 0.85},
        "range": {"type": "telemetry", "key": "range"},
        "temperature": {"type": "telemetry", "key": "temp.mosfet"},
        "color": {"type": "literal", "value": 4278238336},
        "textColor": {"type": "literal", "value": 4294967295},
        "accentColor": {"type": "literal", "value": 4286611584},
        "showRange": {"type": "literal", "value": true},
        "showTemperature": {"type": "literal", "value": true},
        "unit": {"type": "literal", "value": "km"},
        "tempUnit": {"type": "literal", "value": "°C"},
        "fontSize": {"type": "literal", "value": 32},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 450},
        "height": {"type": "literal", "value": 80},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Inter"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": -0.5}
      },
      "level": "basic"
    },
    {
      "id": "time_display",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1700, 850],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "10:54"},
        "fontSize": {"type": "literal", "value": 40},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 160},
        "height": {"type": "literal", "value": 70},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Inter"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": -0.5}
      },
      "level": "basic"
    },
    {
      "id": "gear_selector",
      "kind": "gear_selector",
      "transform": [1, 0, 0, 1, 1450, 850],
      "z": 15,
      "properties": {
        "currentGear": {"type": "literal", "value": "P"},
        "gears": {"type": "literal", "value": "P,R,N,D"},
        "activeColor": {"type": "literal", "value": 4294967295},
        "inactiveColor": {"type": "literal", "value": 4286611584},
        "fontSize": {"type": "literal", "value": 40},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 240},
        "height": {"type": "literal", "value": 70},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Inter"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": -0.5}
      },
      "level": "basic"
    },
    {
      "id": "warnings",
      "kind": "warnings",
      "transform": [1, 0, 0, 1, 1750, 50],
      "z": 20,
      "properties": {
        "activeWarnings": {"type": "literal", "value": "door,seatbelt"},
        "color": {"type": "literal", "value": 4294901760},
        "warningColor": {"type": "literal", "value": 4294963200},
        "infoColor": {"type": "literal", "value": 4294967295},
        "iconSize": {"type": "literal", "value": 40},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 140},
        "height": {"type": "literal", "value": 70}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278190080,
  "accent": 4294967295
}''',
  ),
  _makeAdvancedTemplate(
    id: 'porsche-taycan',
    name: 'Porsche Taycan',
    description:
        'Porsche Taycan curved display dashboard with twin pod gauges and center map.',
    json: r'''{
  "version": 2,
  "name": "Porsche Taycan",
  "description": "Porsche Taycan curved display dashboard with twin pod gauges and center map",
  "canvas": {"width": 1920.0, "height": 720.0},
  "widgets": [
    {
      "id": "map_bg",
      "kind": "map",
      "transform": [1, 0, 0, 1, 440, 60],
      "z": 1,
      "properties": {
        "showRoute": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4282558444},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 0},
        "width": {"type": "literal", "value": 1040},
        "height": {"type": "literal", "value": 560}
      },
      "level": "basic"
    },
    {
      "id": "speed_display",
      "kind": "text",
      "transform": [1, 0, 0, 1, 860, 20],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "speed"},
        "unit": {"type": "literal", "value": "mph"},
        "fontSize": {"type": "literal", "value": 110},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 0},
        "width": {"type": "literal", "value": 200},
        "height": {"type": "literal", "value": 140},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Outfit"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "left_pod",
      "kind": "car_viz",
      "transform": [1, 0, 0, 1, 80, 80],
      "z": 10,
      "properties": {
        "showRing": {"type": "literal", "value": true},
        "showLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4286611584},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 480},
        "height": {"type": "literal", "value": 480}
      },
      "level": "basic"
    },
    {
      "id": "right_pod",
      "kind": "tripstats",
      "transform": [1, 0, 0, 1, 1360, 80],
      "z": 10,
      "properties": {
        "layoutStyle": {"type": "literal", "value": "porsche"},
        "section1Header": {"type": "literal", "value": "Since 2:03 PM"},
        "label1": {"type": "literal", "value": "Time"},
        "value1": {"type": "literal", "value": "6"},
        "unit1": {"type": "literal", "value": "min"},
        "label2": {"type": "literal", "value": "Dist."},
        "value2": {"type": "literal", "value": "0.0"},
        "unit2": {"type": "literal", "value": "mi"},
        "label3": {"type": "literal", "value": "Consum."},
        "value3": {"type": "literal", "value": "---"},
        "unit3": {"type": "literal", "value": "kWh/100mi"},
        "label4": {"type": "literal", "value": "Speed"},
        "value4": {"type": "literal", "value": "---"},
        "unit4": {"type": "literal", "value": "mph"},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4289836757},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 480},
        "height": {"type": "literal", "value": 480},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Outfit"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "odometer",
      "kind": "text",
      "transform": [1, 0, 0, 1, 220, 615],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "986"},
        "unit": {"type": "literal", "value": "mi"},
        "fontSize": {"type": "literal", "value": 28},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 180},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Outfit"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "battery_range",
      "kind": "battery_range",
      "transform": [1, 0, 0, 1, 760, 620],
      "z": 15,
      "properties": {
        "batteryLevel": {"type": "literal", "value": 0.88},
        "range": {"type": "literal", "value": 295},
        "color": {"type": "literal", "value": 4278238336},
        "textColor": {"type": "literal", "value": 4294967295},
        "accentColor": {"type": "literal", "value": 4286611584},
        "showRange": {"type": "literal", "value": true},
        "showTemperature": {"type": "literal", "value": false},
        "unit": {"type": "literal", "value": "mi"},
        "fontSize": {"type": "literal", "value": 28},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 400},
        "height": {"type": "literal", "value": 70},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Outfit"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "drive_mode",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1460, 620],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "NORMAL"},
        "fontSize": {"type": "literal", "value": 28},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 180},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Outfit"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "gear_selector",
      "kind": "gear_selector",
      "transform": [1, 0, 0, 1, 1680, 560],
      "z": 15,
      "properties": {
        "currentGear": {"type": "literal", "value": "P"},
        "gears": {"type": "literal", "value": "R,N,D,P"},
        "activeColor": {"type": "literal", "value": 4280475118},
        "inactiveColor": {"type": "literal", "value": 4286611584},
        "fontSize": {"type": "literal", "value": 30},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 140},
        "height": {"type": "literal", "value": 120},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Outfit"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278521124,
  "accent": 4294967295
}''',
  ),
  _makeAdvancedTemplate(
    id: 'bmw-classic',
    name: 'BMW Classic Cluster',
    description:
        'Classic BMW 4-gauge cluster with amber illumination and digital trip strip.',
    json: r'''{
  "version": 2,
  "name": "BMW Classic Cluster",
  "description": "Classic BMW 4-gauge cluster with amber illumination and digital trip strip",
  "canvas": {"width": 1920.0, "height": 800.0},
  "widgets": [
    {
      "id": "fuel_gauge",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 60, 240],
      "z": 10,
      "properties": {
        "needleStyle": {"type": "literal", "value": "needle"},
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "literal", "value": 0.75},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 1},
        "label": {"type": "literal", "value": "Fuel"},
        "tickCount": {"type": "literal", "value": 4},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4294931456},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 18},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 240},
        "height": {"type": "literal", "value": 240},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/TitilliumWeb"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 1.0}
      },
      "level": "basic"
    },
    {
      "id": "speedometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 320, 100],
      "z": 10,
      "properties": {
        "needleStyle": {"type": "literal", "value": "needle"},
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "telemetry", "key": "speed"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 260},
        "label": {"type": "literal", "value": "km/h"},
        "tickCount": {"type": "literal", "value": 13},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4294931456},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 24},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 560},
        "height": {"type": "literal", "value": 560},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/TitilliumWeb"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 1.0}
      },
      "level": "basic"
    },
    {
      "id": "tachometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1040, 100],
      "z": 10,
      "properties": {
        "needleStyle": {"type": "literal", "value": "needle"},
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "literal", "value": 2.4},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 7},
        "label": {"type": "literal", "value": "1/min x 1000"},
        "tickCount": {"type": "literal", "value": 7},
        "showTickLabels": {"type": "literal", "value": true},
        "redlineStart": {"type": "literal", "value": 0.85},
        "redlineColor": {"type": "literal", "value": 4294901760},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4294931456},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 24},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 560},
        "height": {"type": "literal", "value": 560},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/TitilliumWeb"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 1.0}
      },
      "level": "basic"
    },
    {
      "id": "temp_gauge",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1620, 240],
      "z": 10,
      "properties": {
        "needleStyle": {"type": "literal", "value": "needle"},
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "telemetry", "key": "temp.mosfet"},
        "min": {"type": "literal", "value": 50},
        "max": {"type": "literal", "value": 125},
        "label": {"type": "literal", "value": "Temp °C"},
        "tickCount": {"type": "literal", "value": 4},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4294931456},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 18},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 240},
        "height": {"type": "literal", "value": 240},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/TitilliumWeb"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 1.0}
      },
      "level": "basic"
    },
    {
      "id": "center_temp",
      "kind": "text",
      "transform": [1, 0, 0, 1, 880, 160],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "+30.5 °C"},
        "fontSize": {"type": "literal", "value": 26},
        "color": {"type": "literal", "value": 4294931456},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 160},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/TitilliumWeb"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 1.0}
      },
      "level": "basic"
    },
    {
      "id": "center_digital_strip",
      "kind": "text",
      "transform": [1, 0, 0, 1, 740, 620],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "TOTAL 00038 km   TRIP 0008.1 km   COMFORT P"},
        "fontSize": {"type": "literal", "value": 22},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 6},
        "width": {"type": "literal", "value": 440},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/TitilliumWeb"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 1.0}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278190080,
  "accent": 4294931456
}''',
  ),
  _makeAdvancedTemplate(
    id: 'audi-virtual-cockpit',
    name: 'Audi Virtual Cockpit',
    description:
        'Audi Virtual Cockpit twin dial cluster with center map and vertical LED side meters.',
    json: r'''{
  "version": 2,
  "name": "Audi Virtual Cockpit",
  "description": "Audi Virtual Cockpit twin dial cluster with center map and vertical LED side meters",
  "canvas": {"width": 1920.0, "height": 720.0},
  "widgets": [
    {
      "id": "center_map",
      "kind": "map",
      "transform": [1, 0, 0, 1, 660, 90],
      "z": 1,
      "properties": {
        "showRoute": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 0},
        "width": {"type": "literal", "value": 600},
        "height": {"type": "literal", "value": 500}
      },
      "level": "basic"
    },
    {
      "id": "tachometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 100, 80],
      "z": 10,
      "properties": {
        "needleStyle": {"type": "literal", "value": "needle"},
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "literal", "value": 2.5},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 8},
        "label": {"type": "literal", "value": "1/min x 1000"},
        "tickCount": {"type": "literal", "value": 8},
        "showTickLabels": {"type": "literal", "value": true},
        "redlineStart": {"type": "literal", "value": 0.82},
        "redlineColor": {"type": "literal", "value": 4293796352},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 20},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 520},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/BarlowCondensed"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": 1.5}
      },
      "level": "basic"
    },
    {
      "id": "speedometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1300, 80],
      "z": 10,
      "properties": {
        "needleStyle": {"type": "literal", "value": "needle"},
        "showCenterText": {"type": "literal", "value": true},
        "value": {"type": "telemetry", "key": "speed"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 300},
        "label": {"type": "literal", "value": "km/h"},
        "tickCount": {"type": "literal", "value": 15},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 90},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 520},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/BarlowCondensed"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": 1.5}
      },
      "level": "basic"
    },
    {
      "id": "temp_bar",
      "kind": "minigauge",
      "transform": [1, 0, 0, 1, 15, 200],
      "z": 15,
      "properties": {
        "style": {"type": "literal", "value": "bar"},
        "value": {"type": "telemetry", "key": "temp.mosfet"},
        "min": {"type": "literal", "value": 50},
        "max": {"type": "literal", "value": 130},
        "label": {"type": "literal", "value": "C"},
        "unit": {"type": "literal", "value": "H"},
        "icon": {"type": "literal", "value": "temp"},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 16},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 75},
        "height": {"type": "literal", "value": 280},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/BarlowCondensed"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": 1.5}
      },
      "level": "basic"
    },
    {
      "id": "fuel_bar",
      "kind": "minigauge",
      "transform": [1, 0, 0, 1, 1830, 200],
      "z": 15,
      "properties": {
        "style": {"type": "literal", "value": "bar"},
        "value": {"type": "telemetry", "key": "battery_pct"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 100},
        "label": {"type": "literal", "value": "R"},
        "unit": {"type": "literal", "value": "1/1"},
        "icon": {"type": "literal", "value": "fuel"},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 16},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 75},
        "height": {"type": "literal", "value": 280},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/BarlowCondensed"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": 1.5}
      },
      "level": "basic"
    },
    {
      "id": "top_tab_bar",
      "kind": "text",
      "transform": [1, 0, 0, 1, 760, 30],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDE97  Vehicle    \uD83C\uDFB5  Media    \uD83D\uDCDE  Phone    \uD83D\uDDFA\uFE0F  NAV"},
        "fontSize": {"type": "literal", "value": 20},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 400},
        "height": {"type": "literal", "value": 40},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/BarlowCondensed"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": 1.5}
      },
      "level": "basic"
    },
    {
      "id": "bottom_info_strip",
      "kind": "text",
      "transform": [1, 0, 0, 1, 700, 630],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "33584 km   15:08   1182.1 km   +19.5 °C"},
        "fontSize": {"type": "literal", "value": 22},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 6},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/BarlowCondensed"},
        "fontWeight": {"type": "literal", "value": "w300"},
        "letterSpacing": {"type": "literal", "value": 1.5}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278190080,
  "accent": 4280456191
}''',
  ),
  _makeAdvancedTemplate(
    id: 'vesc-mobile',
    name: 'VESC Mobile Realtime Telemetry',
    description:
        'VESC Tool mobile realtime telemetry dashboard with multi-dial array, battery, and speed gauges.',
    json: r'''{
  "version": 2,
  "name": "VESC Mobile Realtime Telemetry",
  "description": "VESC Tool mobile realtime telemetry dashboard with multi-dial array",
  "canvas": {"width": 1920.0, "height": 1080.0},
  "widgets": [
    {
      "id": "top_tabs",
      "kind": "text",
      "transform": [1, 0, 0, 1, 0, 0],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "START       RT DATA       BMS       PROFILES       VESC BUS       TERMINAL"},
        "fontSize": {"type": "literal", "value": 20},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4280953388},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 1920},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "gauge_current",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 40, 80],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "current.motor"},
        "min": {"type": "literal", "value": -60},
        "max": {"type": "literal", "value": 60},
        "label": {"type": "literal", "value": "CURRENT"},
        "centerUnit": {"type": "literal", "value": "A"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 12},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 160},
        "fontSize": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 320},
        "height": {"type": "literal", "value": 320},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "gauge_power",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 380, 60],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "power"},
        "min": {"type": "literal", "value": -10000},
        "max": {"type": "literal", "value": 10000},
        "label": {"type": "literal", "value": "POWER"},
        "centerUnit": {"type": "literal", "value": "W"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 10},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 180},
        "fontSize": {"type": "literal", "value": 40},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 360},
        "height": {"type": "literal", "value": 360},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "gauge_duty",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 760, 80],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "duty_cycle"},
        "min": {"type": "literal", "value": -100},
        "max": {"type": "literal", "value": 100},
        "label": {"type": "literal", "value": "DUTY"},
        "centerUnit": {"type": "literal", "value": "%"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 8},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 160},
        "fontSize": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 320},
        "height": {"type": "literal", "value": 320},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "gauge_temp_esc",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 40, 480],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "temp.mosfet"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 100},
        "label": {"type": "literal", "value": "TEMP ESC"},
        "centerUnit": {"type": "literal", "value": "°C"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 10},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 160},
        "fontSize": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 320},
        "height": {"type": "literal", "value": 320},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "gauge_consumption",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 380, 500],
      "z": 10,
      "properties": {
        "value": {"type": "literal", "value": 0},
        "min": {"type": "literal", "value": -50},
        "max": {"type": "literal", "value": 50},
        "label": {"type": "literal", "value": "CONSUMP."},
        "centerUnit": {"type": "literal", "value": "WH/KM"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 10},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 180},
        "fontSize": {"type": "literal", "value": 40},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 360},
        "height": {"type": "literal", "value": 360},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "gauge_temp_motor",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 760, 480],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "temp.motor"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 100},
        "label": {"type": "literal", "value": "TEMP MOTOR"},
        "centerUnit": {"type": "literal", "value": "°C"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 10},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 160},
        "fontSize": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 320},
        "height": {"type": "literal", "value": 320},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "main_speed",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1140, 100],
      "z": 10,
      "properties": {
        "value": {"type": "telemetry", "key": "speed"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 70},
        "label": {"type": "literal", "value": "SPEED"},
        "centerUnit": {"type": "literal", "value": "KM/H"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 7},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 300},
        "fontSize": {"type": "literal", "value": 80},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 600},
        "height": {"type": "literal", "value": 600},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "battery_subdial",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1600, 240],
      "z": 15,
      "properties": {
        "value": {"type": "telemetry", "key": "battery_pct"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 100},
        "label": {"type": "literal", "value": "BATTERY"},
        "centerUnit": {"type": "literal", "value": "%"},
        "showCenterText": {"type": "literal", "value": true},
        "tickCount": {"type": "literal", "value": 10},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "borderRadius": {"type": "literal", "value": 140},
        "fontSize": {"type": "literal", "value": 32},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 280},
        "height": {"type": "literal", "value": 280},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "bottom_telemetry_strip",
      "kind": "text",
      "transform": [1, 0, 0, 1, 0, 980],
      "z": 20,
      "properties": {
        "value": {"type": "literal", "value": "ODOMETER 0.0          TRIP 0.0          UP-TIME 00:00:00          Connected (TCP) to 192.168.2.188"},
        "fontSize": {"type": "literal", "value": 22},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4279308561},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 1920},
        "height": {"type": "literal", "value": 100},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Rajdhani"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278585361,
  "accent": 4280456191
}''',
  ),
  _makeAdvancedTemplate(
    id: 'android-auto',
    name: 'Android Auto Coolwalk',
    description:
        'Android Auto Coolwalk split-screen layout with navigation map and media player card.',
    json: r'''{
  "version": 2,
  "name": "Android Auto Coolwalk",
  "description": "Android Auto Coolwalk split-screen layout with navigation and media player",
  "canvas": {"width": 1920.0, "height": 720.0},
  "widgets": [
    {
      "id": "left_rail",
      "kind": "text",
      "transform": [1, 0, 0, 1, 0, 0],
      "z": 20,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDCF6\n6:55\n\n\uD83D\uDDFA\uFE0F\n\n\uD83C\uDFB5\n\n\uD83D\uDCDE\n\n\uD83C\uDF99\uFE0F\n\n\n\n::: "},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4278190080},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 100},
        "height": {"type": "literal", "value": 720},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Roboto"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "nav_map",
      "kind": "map",
      "transform": [1, 0, 0, 1, 100, 0],
      "z": 1,
      "properties": {
        "showRoute": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4278717967},
        "padding": {"type": "literal", "value": 0},
        "width": {"type": "literal", "value": 1170},
        "height": {"type": "literal", "value": 720}
      },
      "level": "basic"
    },
    {
      "id": "turn_card",
      "kind": "text",
      "transform": [1, 0, 0, 1, 130, 20],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "\u2B06\uFE0F   2 mi   Interstate 5 N\nThen \u21B0"},
        "fontSize": {"type": "literal", "value": 22},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4280975662},
        "borderRadius": {"type": "literal", "value": 16},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 420},
        "height": {"type": "literal", "value": 110},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Roboto"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "eta_card",
      "kind": "text",
      "transform": [1, 0, 0, 1, 130, 540],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "\u274C   27 min \u00B7 8.3 mi\n      7:22 AM"},
        "fontSize": {"type": "literal", "value": 22},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4280427042},
        "borderRadius": {"type": "literal", "value": 16},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 420},
        "height": {"type": "literal", "value": 140},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Roboto"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "media_card",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1290, 15],
      "z": 10,
      "properties": {
        "value": {"type": "literal", "value": "\uD83C\uDFB5  Spotify\n\n\n\n\n\nYou got to listen\nMichael Evans\n\n  \u23EE\uFE0F     \u23F8\uFE0F     \u23ED\uFE0F"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4281351540},
        "borderRadius": {"type": "literal", "value": 24},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 615},
        "height": {"type": "literal", "value": 690},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Roboto"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278190080,
  "accent": 4280456191
}''',
  ),
  _makeAdvancedTemplate(
    id: 'carplay',
    name: 'Apple CarPlay Dashboard',
    description:
        'Apple CarPlay dashboard layout with left vertical dock and app icon grid.',
    json: r'''{
  "version": 2,
  "name": "Apple CarPlay Dashboard",
  "description": "Apple CarPlay dashboard layout with left vertical dock and app icon grid",
  "canvas": {"width": 1920.0, "height": 1080.0},
  "widgets": [
    {
      "id": "left_dock",
      "kind": "text",
      "transform": [1, 0, 0, 1, 30, 30],
      "z": 10,
      "properties": {
        "value": {"type": "literal", "value": "09:41\n\uD83D\uDCF6 4G\n\n\n\uD83D\uDDFA\uFE0F\n\n\uD83C\uDFB5\n\n\u2699\uFE0F\n\n\n\n\n\n\uD83D\uDD32"},
        "fontSize": {"type": "literal", "value": 26},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4279834905},
        "borderRadius": {"type": "literal", "value": 28},
        "padding": {"type": "literal", "value": 16},
        "width": {"type": "literal", "value": 120},
        "height": {"type": "literal", "value": 1020},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_phone",
      "kind": "text",
      "transform": [1, 0, 0, 1, 200, 80],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDCDE\n\nPhone"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4281519411},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_music",
      "kind": "text",
      "transform": [1, 0, 0, 1, 530, 80],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83C\uDFB5\n\nMusic"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4294908976},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_maps",
      "kind": "text",
      "transform": [1, 0, 0, 1, 860, 80],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDDFA\uFE0F\n\nMaps"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4283818318},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_messages",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1190, 80],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDCAC\n\nMessages"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4281519411},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_now_playing",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1520, 80],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDCCA\n\nNow Playing"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4278190080},
        "backgroundColor": {"type": "literal", "value": 4294967295},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_podcasts",
      "kind": "text",
      "transform": [1, 0, 0, 1, 200, 520],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83C\uDF99\uFE0F\n\nPodcasts"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4287840476},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_audiobooks",
      "kind": "text",
      "transform": [1, 0, 0, 1, 530, 520],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDCDA\n\nAudiobooks"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4294931456},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_weather",
      "kind": "text",
      "transform": [1, 0, 0, 1, 860, 520],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83C\uDF24\uFE0F\n\nWeather"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4280475118},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_calendar",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1190, 520],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\uD83D\uDCC5\n\nCalendar"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4278190080},
        "backgroundColor": {"type": "literal", "value": 4294967295},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "app_settings",
      "kind": "text",
      "transform": [1, 0, 0, 1, 1520, 520],
      "z": 5,
      "properties": {
        "value": {"type": "literal", "value": "\u2699\uFE0F\n\nSettings"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 4284572005},
        "borderRadius": {"type": "literal", "value": 36},
        "padding": {"type": "literal", "value": 24},
        "width": {"type": "literal", "value": 300},
        "height": {"type": "literal", "value": 400},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    },
    {
      "id": "page_dots",
      "kind": "text",
      "transform": [1, 0, 0, 1, 940, 980],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "\u25CF   \u25CB   \u25CB   \u25CB"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 200},
        "height": {"type": "literal", "value": 40},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Manrope"},
        "fontWeight": {"type": "literal", "value": "w600"},
        "letterSpacing": {"type": "literal", "value": -0.2}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278523955,
  "accent": 4294967295
}''',
  ),
  _makeAdvancedTemplate(
    id: 'ford-digital',
    name: 'Ford Digital Cluster',
    description:
        'Ford electric blue digital cluster with twin glowing dials and lane assistance view.',
    json: r'''{
  "version": 2,
  "name": "Ford Digital Cluster",
  "description": "Ford electric blue digital cluster with twin glowing dials and lane assistance view",
  "canvas": {"width": 1920.0, "height": 720.0},
  "widgets": [
    {
      "id": "speedometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 100, 100],
      "z": 10,
      "properties": {
        "showCenterText": {"type": "literal", "value": true},
        "value": {"type": "telemetry", "key": "speed"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 240},
        "centerUnit": {"type": "literal", "value": "km/h"},
        "tickCount": {"type": "literal", "value": 12},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4278225151},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 110},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 520},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Exo2"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "power_dial",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1300, 100],
      "z": 10,
      "properties": {
        "showCenterText": {"type": "literal", "value": true},
        "value": {"type": "telemetry", "key": "power"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 180},
        "centerUnit": {"type": "literal", "value": "kW"},
        "tickCount": {"type": "literal", "value": 6},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4278225151},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 70},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 520},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Exo2"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    },
    {
      "id": "assistance_view",
      "kind": "car_viz",
      "transform": [1, 0, 0, 1, 660, 140],
      "z": 10,
      "properties": {
        "label": {"type": "literal", "value": "Guide VÉ"},
        "laneLeft": {"type": "literal", "value": true},
        "laneRight": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4278225151},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 12},
        "width": {"type": "literal", "value": 600},
        "height": {"type": "literal", "value": 440}
      },
      "level": "basic"
    },
    {
      "id": "bottom_bar",
      "kind": "text",
      "transform": [1, 0, 0, 1, 640, 630],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "99485.2 km   -3°   P R N D L   \u26FD 253 km"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 640},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Exo2"},
        "fontWeight": {"type": "literal", "value": "w700"},
        "letterSpacing": {"type": "literal", "value": 0.0}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278198106,
  "accent": 4278225151
}''',
  ),
  _makeAdvancedTemplate(
    id: 'vw-digital',
    name: 'VW Digital Cockpit',
    description:
        'Volkswagen Digital Cockpit with full-width navigation map and twin active info dials.',
    json: r'''{
  "version": 2,
  "name": "VW Digital Cockpit",
  "description": "Volkswagen Digital Cockpit with full-width navigation map and twin active info dials",
  "canvas": {"width": 1920.0, "height": 720.0},
  "widgets": [
    {
      "id": "full_map",
      "kind": "map",
      "transform": [1, 0, 0, 1, 0, 0],
      "z": 1,
      "properties": {
        "showRoute": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 4278190080},
        "padding": {"type": "literal", "value": 0},
        "width": {"type": "literal", "value": 1920},
        "height": {"type": "literal", "value": 720}
      },
      "level": "basic"
    },
    {
      "id": "tachometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 80, 80],
      "z": 10,
      "properties": {
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "literal", "value": 2.2},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 8},
        "label": {"type": "literal", "value": "1/min x 1000"},
        "tickCount": {"type": "literal", "value": 8},
        "showTickLabels": {"type": "literal", "value": true},
        "redlineStart": {"type": "literal", "value": 0.81},
        "redlineColor": {"type": "literal", "value": 4294901760},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4294901760},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 20},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 520},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Sora"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "left_trip_info",
      "kind": "tripstats",
      "transform": [1, 0, 0, 1, 220, 220],
      "z": 15,
      "properties": {
        "label1": {"type": "literal", "value": "Since start"},
        "value1": {"type": "literal", "value": "6.2"},
        "unit1": {"type": "literal", "value": "km/l"},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4289836757},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 24},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 240},
        "height": {"type": "literal", "value": 240},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Sora"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "speedometer",
      "kind": "gauge",
      "transform": [1, 0, 0, 1, 1320, 80],
      "z": 10,
      "properties": {
        "showCenterText": {"type": "literal", "value": false},
        "value": {"type": "telemetry", "key": "speed"},
        "min": {"type": "literal", "value": 0},
        "max": {"type": "literal", "value": 320},
        "label": {"type": "literal", "value": "km/h"},
        "tickCount": {"type": "literal", "value": 16},
        "showTickLabels": {"type": "literal", "value": true},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4280456191},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 20},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 520},
        "height": {"type": "literal", "value": 520},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Sora"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "right_range_info",
      "kind": "tripstats",
      "transform": [1, 0, 0, 1, 1460, 220],
      "z": 15,
      "properties": {
        "label1": {"type": "literal", "value": "Driving range"},
        "value1": {"type": "literal", "value": "90"},
        "unit1": {"type": "literal", "value": "km"},
        "color": {"type": "literal", "value": 4294967295},
        "accent": {"type": "literal", "value": 4289836757},
        "backgroundColor": {"type": "literal", "value": 0},
        "fontSize": {"type": "literal", "value": 24},
        "padding": {"type": "literal", "value": 8},
        "width": {"type": "literal", "value": 240},
        "height": {"type": "literal", "value": 240},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Sora"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "top_bar",
      "kind": "text",
      "transform": [1, 0, 0, 1, 760, 20],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "08:29pm   33.0°C"},
        "fontSize": {"type": "literal", "value": 22},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 4},
        "width": {"type": "literal", "value": 400},
        "height": {"type": "literal", "value": 40},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Sora"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    },
    {
      "id": "bottom_bar",
      "kind": "text",
      "transform": [1, 0, 0, 1, 660, 640],
      "z": 15,
      "properties": {
        "value": {"type": "literal", "value": "trip 13.0 km   72163km"},
        "fontSize": {"type": "literal", "value": 24},
        "color": {"type": "literal", "value": 4294967295},
        "backgroundColor": {"type": "literal", "value": 0},
        "padding": {"type": "literal", "value": 6},
        "width": {"type": "literal", "value": 600},
        "height": {"type": "literal", "value": 50},
        "fontFamily": {"type": "literal", "value": "packages/widgets_library/Sora"},
        "fontWeight": {"type": "literal", "value": "w500"},
        "letterSpacing": {"type": "literal", "value": 0.3}
      },
      "level": "basic"
    }
  ],
  "graphs": {},
  "background": 4278190080,
  "accent": 4280456191
}''',
  ),
];
