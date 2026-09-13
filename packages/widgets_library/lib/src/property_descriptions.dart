/// One-line, plain-language descriptions of what a property actually does —
/// shown as a tooltip on each property row in the Studio inspector. Most
/// property keys are reused across many widget kinds with the same meaning
/// (`value`, `min`, `color`, `padding`...), so this is keyed by the *base*
/// key rather than duplicated per kind — see [propertyDescription].
library;

/// Strips a numbered-slot suffix so `label1`..`label4`, `unit2_3`, and
/// `section1Header` all resolve to the same description as their base
/// concept (`label`, `unit`, `sectionHeader`) — several multi-stat widgets
/// (tripstats, the Tesla/Android-Auto grid layouts) repeat the same few
/// concepts across 3-4 numbered slots.
String _baseKey(String key) {
  // Strips every digit run (with an optional leading underscore) wherever
  // it appears: "label1" -> "label", "unit1_2" -> "unit",
  // "section1Val1" -> "sectionVal", "section2Header" -> "sectionHeader".
  final stripped = key.replaceAll(RegExp(r'_?\d+'), '');
  return stripped.isEmpty
      ? key
      : stripped[0].toLowerCase() + stripped.substring(1);
}

const Map<String, String> _descriptions = {
  'value': 'The bound value this widget displays or reacts to.',
  'label': 'A short caption shown alongside the value.',
  'unit': 'A unit suffix shown next to the value (e.g. "km/h", "°C").',
  'min': 'The value that maps to the low end of the scale/gauge sweep.',
  'max': 'The value that maps to the high end of the scale/gauge sweep.',
  'color': 'The main foreground colour (the value/needle/fill itself).',
  'accent': 'A secondary colour, used for labels and less prominent parts.',
  'backgroundColor':
      'Fill colour behind the widget. Transparent by default — most '
          'widgets look better without a boxed background.',
  'borderColor': 'Outline colour, only visible when borderWidth is above 0.',
  'borderWidth': 'Outline thickness in pixels. 0 means no visible border.',
  'borderRadius': 'How rounded the corners are, in pixels.',
  'padding': 'Empty space between the widget\'s edge and its content.',
  'opacity': 'Overall transparency, from 0 (invisible) to 1 (fully opaque).',
  'visible': 'Whether this widget renders at all.',
  'width': 'The widget\'s box width in canvas pixels.',
  'height': 'The widget\'s box height in canvas pixels.',
  'fontSize': 'Text size in pixels for the main value.',
  'fontFamily':
      'Typeface for this widget\'s text. "Default" inherits the dashboard\'s '
          'overall font rather than overriding it.',
  'fontWeight': 'Text boldness, from Thin to Black.',
  'letterSpacing': 'Extra space between characters — negative tightens it.',
  'shadowColor': 'Drop-shadow colour, only visible when shadowBlur is above 0.',
  'shadowBlur': 'How soft/spread-out the drop shadow is. 0 means no shadow.',
  'shadowOffsetY': 'Vertical offset of the drop shadow, in pixels.',
  'icon': 'Which built-in icon to show (e.g. "battery", "temp", "power").',
  'iconSize': 'Icon size in pixels.',
  'style': 'Which visual layout variant this widget uses.',
  'orientation': 'Horizontal or vertical layout.',
  'layoutStyle': 'Which preset layout this widget uses.',
  'columns': 'How many columns the grid/stat layout is split into.',
  'showValue': 'Whether the numeric reading is overlaid on top of the fill.',
  'showUnit': 'Whether the unit suffix is shown next to the value.',
  'showGrid': 'Whether faint gridlines are drawn behind the plotted line.',
  'showLabels': 'Whether text labels are shown alongside the icons/values.',
  'showBars': 'Whether the power/regen bar graph is shown below the reading.',
  'showTickLabels':
      'Whether numbers are printed next to the gauge\'s tick marks.',
  'showCenterText':
      'Whether a digital readout is shown in the gauge\'s centre.',
  'tickCount': 'How many tick marks are drawn around the gauge.',
  'sweepAngle': 'How many degrees of arc the gauge sweeps through.',
  'startAngle': 'The compass angle (in degrees) where the gauge scale starts.',
  'arcWidth': 'Thickness of the gauge\'s arc track, in pixels.',
  'needleStyle': 'Shape of the value indicator: a thin needle or a filled arc.',
  'redlineStart':
      'Where the danger-zone colour begins, as a fraction of min..max '
          '(0.8 = the last 20% of the scale).',
  'redlineColor': 'Colour used for the danger-zone portion of the scale.',
  'centerValue': 'A second bound value shown as digital text in the centre.',
  'centerUnit': 'Unit suffix for the centre digital readout.',
  'innerValue': 'A secondary bound value shown on an inner ring/scale.',
  'innerMin': 'Low end of the inner ring\'s scale.',
  'innerMax': 'High end of the inner ring\'s scale.',
  'innerColor': 'Colour of the inner ring/scale.',
  'innerArcWidth': 'Thickness of the inner ring\'s arc track.',
  'lineWidth': 'Thickness of the plotted line, in pixels.',
  'smoothCurve':
      'Whether the line is drawn as a smooth curve instead of straight segments.',
  'fillArea': 'Whether the area under the line is filled in.',
  'fillColor': 'Fill colour used when fillArea is on.',
  'gridColor': 'Colour of the background gridlines.',
  'window': 'How many recent samples are kept and plotted.',
  'gradient':
      'Whether the fill uses a colour gradient instead of a flat colour.',
  'gradientColor': 'The second colour in the gradient fill.',
  'barRadius': 'Corner radius of the fill bar itself (separate from the box).',
  'barWidth': 'Thickness of the bar, in pixels.',
  'barHeight': 'Height of the bar, in pixels.',
  'src': 'File path or asset key of the image to display.',
  'fit': 'How the image is scaled to fill its box (cover, contain, etc).',
  'tint': 'An overlay colour tinting the image.',
  'url': 'The web address to load.',
  'title': 'A caption shown above/alongside the embedded content.',
  'js': 'Whether JavaScript is enabled for the embedded web page.',
  'program': 'The custom paint program (drawn shape/pattern) for this widget.',
  'sourceUnit': 'The unit the bound value is already in — only matters when '
      'displayUnit is also set, to convert between the two.',
  'displayUnit':
      'Convert the value to this unit for display. Leave blank to show it '
          'exactly as bound, with no conversion.',
  'tempUnit': 'Unit shown for temperature readings on this widget.',
  'mapStyle': 'Visual style/theme of the map tiles.',
  'showRing': 'Whether a status ring is drawn around the icon.',
  'activeColor': 'Colour used when this indicator/state is active.',
  'inactiveColor': 'Colour used when this indicator/state is inactive.',
  'warningColor': 'Colour used for warning-severity items.',
  'infoColor': 'Colour used for informational (non-warning) items.',
  'textColor': 'Colour of any plain text on this widget.',
  'apps': 'Comma-separated list of app icons to show, in order.',
  'activeWarnings': 'Comma-separated list of currently-active warning ids.',
  'gears': 'Comma-separated list of gear labels, in display order.',
  'currentGear': 'Which gear label is currently highlighted.',
  'progress': 'How far along a process/route is, from 0 to 1.',
  'eta': 'Estimated time remaining, shown as text.',
  'distance': 'Distance value shown for this leg/segment.',
  'nextTurn': 'Text describing the next navigation instruction.',
  'signal': 'Signal-strength level shown by the indicator.',
  'showSignal': 'Whether the signal-strength indicator is shown.',
  'battery': 'Battery level, usually as a percentage.',
  'batteryLevel': 'Battery level, usually as a percentage.',
  'showBattery': 'Whether the battery indicator is shown.',
  'range': 'Estimated remaining range.',
  'showRange': 'Whether the estimated-range text is shown.',
  'temperature': 'Temperature value shown by this widget.',
  'targetTemp': 'The target/set-point temperature.',
  'showTemperature': 'Whether the temperature reading is shown.',
  'fanSpeed': 'Fan speed level shown by the climate widget.',
  'mode': 'Which mode this widget is currently displaying/set to.',
  'showMapGraphic': 'Whether a small map/route graphic is shown.',
  'showControls':
      'Whether interactive controls are shown alongside the display.',
  'showTime': 'Whether a time/clock readout is shown.',
  'time': 'Time value or label shown by this widget.',
  'duration': 'A duration value, usually shown as mm:ss or hh:mm.',
  'album': 'Album name shown in the now-playing display.',
  'albumColor': 'Background colour used behind the album artwork placeholder.',
  'artist': 'Artist name shown in the now-playing display.',
  'maxPower': 'The power value that represents a "full" bar graph.',
  'maxRegen':
      'The regen value that represents a "full" bar graph on the regen side.',
  'power': 'The bound power/wattage value.',
  'regen': 'The bound regenerative-braking power value.',
  'regenColor': 'Colour used for the regenerative-braking side of the display.',
  'fault': 'The bound fault/error code.',
  'doorLeft': 'Whether the left door is shown as open.',
  'doorRight': 'Whether the right door is shown as open.',
  'laneLeft': 'Whether the left lane-departure indicator is active.',
  'laneRight': 'Whether the right lane-departure indicator is active.',
  'carAhead': 'Whether the "car ahead" proximity indicator is active.',
  'subLabel': 'A smaller secondary caption shown below the main label.',
  'subValue': 'A secondary bound value shown below the main value.',
  'sectionHeader': 'A caption shown above this group of stats.',
  'sectionVal': 'A bound value within this group of stats.',
};

/// A one-line, plain-language description of what a property does, keyed by
/// its base concept (numbered-slot suffixes stripped — see [_baseKey]).
/// Falls back to [fallbackLabel] (the property's own manifest label) for the
/// less common, highly kind-specific keys not worth a bespoke entry.
String propertyDescription(String key, String fallbackLabel) {
  return _descriptions[_baseKey(key)] ?? 'The $fallbackLabel property.';
}
