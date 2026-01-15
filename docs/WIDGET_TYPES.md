# VescHub Widget Types Reference

**Version:** 1.0  
**Last Updated:** January 2026

## Overview

This document provides detailed specifications for all widget types supported by VescHub dashboards. Each widget type has unique properties and behaviors designed for specific use cases.

## Table of Contents

1. [Text Widget](#text-widget)
2. [Button Widget](#button-widget)
3. [Gauge Widget](#gauge-widget)
4. [Graph Widget](#graph-widget)
5. [Progress Bar Widget](#progress-bar-widget)
6. [Image Widget](#image-widget)
7. [Shape Widget](#shape-widget)
8. [Indicator Widget](#indicator-widget)
9. [Speedometer Widget](#speedometer-widget)

---

## Text Widget

Display static or dynamic text with full typography control.

### Type

```json
{
  "type": "text"
}
```

### Use Cases

- Display numeric values (speed, temperature, voltage)
- Show labels and titles
- Format data with units and decimal places
- Conditional text coloring based on values

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `text` | string | ❌ No | "" | Static text or template with {dataSource} placeholders |
| `dataSource` | string | ❌ No | - | Data source to display |
| `fontFamily` | string | ❌ No | "Roboto" | Font family name |
| `fontSize` | number | ❌ No | 16 | Font size in pixels (8-200) |
| `fontWeight` | string/number | ❌ No | "normal" | Font weight: "normal", "bold", or 100-900 |
| `fontStyle` | string | ❌ No | "normal" | Font style: "normal" or "italic" |
| `textAlign` | string | ❌ No | "left" | Text alignment: "left", "center", "right" |
| `color` | string | ❌ No | "#FFFFFF" | Text color (hex) |
| `backgroundColor` | string | ❌ No | transparent | Background color (hex) |
| `borderWidth` | number | ❌ No | 0 | Border width in pixels |
| `borderColor` | string | ❌ No | "#FFFFFF" | Border color (hex) |
| `borderRadius` | number | ❌ No | 0 | Border radius in pixels |
| `shadow` | object | ❌ No | - | Shadow configuration |
| `prefix` | string | ❌ No | "" | Text to prepend to value |
| `suffix` | string | ❌ No | "" | Text to append to value (e.g., units) |
| `decimals` | integer | ❌ No | 0 | Number of decimal places for numeric values |

### Shadow Object

```json
{
  "shadow": {
    "enabled": true,
    "color": "#000000",
    "blur": 5,
    "offsetX": 0,
    "offsetY": 2
  }
}
```

### Examples

**Simple Static Text:**
```json
{
  "id": "label",
  "type": "text",
  "x": 50,
  "y": 50,
  "width": 200,
  "height": 40,
  "text": "SPEED",
  "fontSize": 18,
  "fontWeight": "bold",
  "color": "#AAAAAA"
}
```

**Dynamic Data with Formatting:**
```json
{
  "id": "speed_display",
  "type": "text",
  "x": 50,
  "y": 100,
  "width": 300,
  "height": 80,
  "dataSource": "speed",
  "text": "{speed}",
  "fontSize": 52,
  "fontWeight": "bold",
  "textAlign": "center",
  "color": "#00FF00",
  "suffix": " km/h",
  "decimals": 1
}
```

**With Conditional Formatting:**
```json
{
  "id": "battery_text",
  "type": "text",
  "x": 100,
  "y": 200,
  "width": 200,
  "height": 60,
  "dataSource": "battery_percent",
  "text": "{battery_percent}",
  "fontSize": 42,
  "suffix": "%",
  "decimals": 0,
  "conditionalFormatting": [
    {
      "condition": "battery_percent < 20",
      "properties": {
        "color": "#FF0000"
      }
    }
  ]
}
```

---

## Button Widget

Interactive button with custom images for different states and configurable actions.

### Type

```json
{
  "type": "button"
}
```

### Use Cases

- Navigate between screens
- Toggle data values
- Trigger actions or commands
- Interactive controls

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `imageUnpressed` | string | ✅ Yes | - | Image path for default/unpressed state |
| `imagePressed` | string | ❌ No | - | Image path for pressed/tapped state |
| `imageDisabled` | string | ❌ No | - | Image path for disabled state |
| `action` | object | ✅ Yes | - | Action configuration |
| `hapticFeedback` | boolean | ❌ No | true | Enable haptic feedback on press |
| `soundOnPress` | string | ❌ No | - | Sound file path to play on press |
| `enabled` | boolean | ❌ No | true | Whether button is enabled |
| `longPressDelay` | integer | ❌ No | 500 | Long press delay in milliseconds |

### Action Object

```json
{
  "action": {
    "type": "switchScreen",
    "target": "screen_id",
    "params": {}
  }
}
```

#### Action Types

| Type | Description | Target |
|------|-------------|--------|
| `switchScreen` | Navigate to another screen | Screen ID |
| `toggleValue` | Toggle a data value | Data source name |
| `sendCommand` | Send command to controller | Command string |
| `function` | Execute custom function | Function name |

### Examples

**Screen Navigation Button:**
```json
{
  "id": "next_button",
  "type": "button",
  "x": 320,
  "y": 20,
  "width": 60,
  "height": 60,
  "imageUnpressed": "/assets/icons/arrow_right.png",
  "imagePressed": "/assets/icons/arrow_right_pressed.png",
  "action": {
    "type": "switchScreen",
    "target": "detailed_view"
  },
  "hapticFeedback": true
}
```

**Toggle Button with Sound:**
```json
{
  "id": "lights_toggle",
  "type": "button",
  "x": 100,
  "y": 500,
  "width": 80,
  "height": 80,
  "imageUnpressed": "/assets/icons/light_off.png",
  "imagePressed": "/assets/icons/light_on.png",
  "imageDisabled": "/assets/icons/light_disabled.png",
  "action": {
    "type": "toggleValue",
    "target": "lights_enabled"
  },
  "soundOnPress": "/assets/sounds/click.wav",
  "hapticFeedback": true
}
```

---

## Gauge Widget

Circular or semicircular gauge for displaying numeric values with visual zones.

### Type

```json
{
  "type": "gauge"
}
```

### Use Cases

- Display speed, RPM, temperature
- Show value ranges with color-coded zones
- Visual representation of analog-style meters

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `dataSource` | string | ✅ Yes | - | Data source to display |
| `gaugeType` | string | ❌ No | "circular" | Gauge type: "circular" or "semicircular" |
| `minValue` | number | ❌ No | 0 | Minimum gauge value |
| `maxValue` | number | ❌ No | 100 | Maximum gauge value |
| `units` | string | ❌ No | - | Unit label (e.g., "km/h", "°C") |
| `needleColor` | string | ❌ No | "#FFFFFF" | Needle/pointer color (hex) |
| `backgroundColor` | string | ❌ No | transparent | Gauge background color (hex) |
| `backgroundImage` | string | ❌ No | - | Background image path |
| `showTicks` | boolean | ❌ No | true | Show tick marks |
| `tickCount` | integer | ❌ No | 10 | Number of tick marks |
| `tickColor` | string | ❌ No | "#FFFFFF" | Tick mark color (hex) |
| `showLabels` | boolean | ❌ No | true | Show value labels |
| `labelFontSize` | number | ❌ No | 12 | Label font size |
| `labelColor` | string | ❌ No | "#FFFFFF" | Label color (hex) |
| `zones` | array | ❌ No | [] | Array of gauge zone objects |

### Zone Object

```json
{
  "from": 0,
  "to": 50,
  "color": "#00FF00",
  "label": "Normal"
}
```

### Examples

**Circular Gauge:**
```json
{
  "id": "voltage_gauge",
  "type": "gauge",
  "x": 50,
  "y": 150,
  "width": 200,
  "height": 200,
  "dataSource": "battery_voltage",
  "gaugeType": "circular",
  "minValue": 40,
  "maxValue": 60,
  "units": "V",
  "needleColor": "#00FFFF",
  "showTicks": true,
  "tickCount": 5,
  "zones": [
    {
      "from": 40,
      "to": 45,
      "color": "#FF0000",
      "label": "Low"
    },
    {
      "from": 45,
      "to": 55,
      "color": "#00FF00",
      "label": "Normal"
    },
    {
      "from": 55,
      "to": 60,
      "color": "#FFFF00",
      "label": "High"
    }
  ]
}
```

**Semicircular Gauge:**
```json
{
  "id": "duty_gauge",
  "type": "gauge",
  "x": 100,
  "y": 300,
  "width": 200,
  "height": 150,
  "dataSource": "duty_cycle",
  "gaugeType": "semicircular",
  "minValue": 0,
  "maxValue": 100,
  "units": "%",
  "needleColor": "#1E88E5"
}
```

---

## Graph Widget

Real-time line or bar charts for plotting data over time.

### Type

```json
{
  "type": "graph"
}
```

### Use Cases

- Plot speed, current, temperature over time
- Compare multiple data series
- Visualize trends and patterns

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `graphType` | string | ❌ No | "line" | Graph type: "line" or "bar" |
| `dataSeries` | array | ✅ Yes | - | Array of data series objects |
| `timeWindow` | integer | ❌ No | 30 | Time window in seconds |
| `backgroundColor` | string | ❌ No | transparent | Graph background color (hex) |
| `gridColor` | string | ❌ No | "#2A2A2A" | Grid line color (hex) |
| `showGrid` | boolean | ❌ No | true | Show grid lines |
| `showXAxis` | boolean | ❌ No | true | Show X axis |
| `showYAxis` | boolean | ❌ No | true | Show Y axis |
| `axisColor` | string | ❌ No | "#FFFFFF" | Axis color (hex) |
| `autoScale` | boolean | ❌ No | true | Auto-scale Y axis |
| `minValue` | number | ❌ No | - | Fixed minimum Y value (when autoScale=false) |
| `maxValue` | number | ❌ No | - | Fixed maximum Y value (when autoScale=false) |

### Data Series Object

```json
{
  "dataSource": "speed",
  "label": "Speed",
  "color": "#00FFFF",
  "lineWidth": 2,
  "lineStyle": "solid"
}
```

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `dataSource` | string | ✅ Yes | - | Data source identifier |
| `label` | string | ❌ No | - | Series label |
| `color` | string | ❌ No | "#FFFFFF" | Line/bar color (hex) |
| `lineWidth` | number | ❌ No | 2 | Line width in pixels |
| `lineStyle` | string | ❌ No | "solid" | Line style: "solid", "dashed", "dotted" |

### Examples

**Single Series Line Graph:**
```json
{
  "id": "speed_graph",
  "type": "graph",
  "x": 30,
  "y": 150,
  "width": 340,
  "height": 160,
  "graphType": "line",
  "timeWindow": 30,
  "backgroundColor": "#1A1A1A",
  "showGrid": true,
  "autoScale": true,
  "dataSeries": [
    {
      "dataSource": "speed",
      "label": "Speed",
      "color": "#00FFFF",
      "lineWidth": 3,
      "lineStyle": "solid"
    }
  ]
}
```

**Multi-Series Graph:**
```json
{
  "id": "power_graph",
  "type": "graph",
  "x": 30,
  "y": 350,
  "width": 340,
  "height": 160,
  "graphType": "line",
  "timeWindow": 60,
  "autoScale": false,
  "minValue": 0,
  "maxValue": 100,
  "dataSeries": [
    {
      "dataSource": "motor_current",
      "label": "Current",
      "color": "#00FF00",
      "lineWidth": 2
    },
    {
      "dataSource": "duty_cycle",
      "label": "Duty Cycle",
      "color": "#FFA500",
      "lineWidth": 2,
      "lineStyle": "dashed"
    }
  ]
}
```

---

## Progress Bar Widget

Horizontal or vertical progress bar with optional gradient support.

### Type

```json
{
  "type": "progressbar"
}
```

### Use Cases

- Display battery level
- Show loading/progress indicators
- Visualize percentage values

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `dataSource` | string | ✅ Yes | - | Data source to display |
| `orientation` | string | ❌ No | "horizontal" | Orientation: "horizontal" or "vertical" |
| `minValue` | number | ❌ No | 0 | Minimum value |
| `maxValue` | number | ❌ No | 100 | Maximum value |
| `fillColor` | string | ❌ No | "#00FF00" | Fill color (hex) |
| `backgroundColor` | string | ❌ No | "#2A2A2A" | Background color (hex) |
| `gradient` | object | ❌ No | - | Gradient configuration |
| `borderRadius` | number | ❌ No | 0 | Border radius in pixels |
| `showValue` | boolean | ❌ No | false | Show value text overlay |
| `valueFontSize` | number | ❌ No | 16 | Value text font size |
| `valueColor` | string | ❌ No | "#FFFFFF" | Value text color (hex) |

### Gradient Object

```json
{
  "gradient": {
    "enabled": true,
    "type": "linear",
    "colors": ["#00FF00", "#FFFF00", "#FF0000"],
    "angle": 90
  }
}
```

### Examples

**Horizontal Battery Bar:**
```json
{
  "id": "battery_bar",
  "type": "progressbar",
  "x": 50,
  "y": 500,
  "width": 300,
  "height": 40,
  "dataSource": "battery_percent",
  "orientation": "horizontal",
  "fillColor": "#00FF00",
  "backgroundColor": "#2A2A2A",
  "borderRadius": 10,
  "showValue": true,
  "valueFontSize": 18,
  "gradient": {
    "enabled": true,
    "type": "linear",
    "colors": ["#00FF00", "#FFFF00"],
    "angle": 90
  }
}
```

**Vertical Progress Bar:**
```json
{
  "id": "temp_bar",
  "type": "progressbar",
  "x": 350,
  "y": 100,
  "width": 30,
  "height": 200,
  "dataSource": "motor_temp",
  "orientation": "vertical",
  "minValue": 20,
  "maxValue": 120,
  "fillColor": "#FF5722",
  "backgroundColor": "#2A2A2A",
  "borderRadius": 5
}
```

---

## Image Widget

Display static or data-driven images with various fit modes.

### Type

```json
{
  "type": "image"
}
```

### Use Cases

- Display logos, icons, backgrounds
- Show data-driven images
- Add visual decorations

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `imagePath` | string | ✅ Yes | - | Path to image file |
| `fitMode` | string | ❌ No | "contain" | How image fits: "fill", "contain", "cover", "stretch", "none" |
| `tintColor` | string | ❌ No | - | Optional tint color (hex) |

### Fit Modes

| Mode | Description |
|------|-------------|
| `fill` | Fill entire widget area (may distort) |
| `contain` | Fit within widget area (maintain aspect ratio) |
| `cover` | Cover entire widget area (may crop) |
| `stretch` | Stretch to widget dimensions |
| `none` | Display at original size |

### Examples

**Logo Display:**
```json
{
  "id": "logo",
  "type": "image",
  "x": 150,
  "y": 50,
  "width": 100,
  "height": 100,
  "imagePath": "/assets/logos/veschub.png",
  "fitMode": "contain"
}
```

**Icon with Conditional Tint:**
```json
{
  "id": "battery_icon",
  "type": "image",
  "x": 30,
  "y": 450,
  "width": 50,
  "height": 70,
  "imagePath": "/assets/icons/battery.png",
  "fitMode": "contain",
  "conditionalFormatting": [
    {
      "condition": "battery_percent < 20",
      "properties": {
        "tintColor": "#FF0000"
      }
    }
  ]
}
```

---

## Shape Widget

Basic geometric shapes for decorative elements or indicators.

### Type

```json
{
  "type": "shape"
}
```

### Use Cases

- Create backgrounds and panels
- Add decorative lines and borders
- Build custom indicators

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `shapeType` | string | ❌ No | "rectangle" | Shape type: "rectangle", "circle", "line", "polygon" |
| `fillColor` | string | ❌ No | transparent | Fill color (hex) |
| `strokeColor` | string | ❌ No | "#FFFFFF" | Stroke/border color (hex) |
| `strokeWidth` | number | ❌ No | 1 | Stroke width in pixels |
| `points` | array | ❌ No | - | Array of point objects for polygon (required for polygon type) |

### Point Object (for polygons)

```json
{
  "x": 50,
  "y": 100
}
```

### Examples

**Rectangle Panel:**
```json
{
  "id": "panel_bg",
  "type": "shape",
  "x": 20,
  "y": 100,
  "width": 360,
  "height": 200,
  "shapeType": "rectangle",
  "fillColor": "#1E1E1E",
  "strokeColor": "#2A2A2A",
  "strokeWidth": 1,
  "borderRadius": 8
}
```

**Decorative Line:**
```json
{
  "id": "divider",
  "type": "shape",
  "x": 50,
  "y": 300,
  "width": 300,
  "height": 2,
  "shapeType": "rectangle",
  "fillColor": "#1E88E5"
}
```

**Circle:**
```json
{
  "id": "indicator_bg",
  "type": "shape",
  "x": 180,
  "y": 380,
  "width": 40,
  "height": 40,
  "shapeType": "circle",
  "fillColor": "#000000",
  "strokeColor": "#FFFFFF",
  "strokeWidth": 2
}
```

---

## Indicator Widget

LED-style boolean indicator with on/off states.

### Type

```json
{
  "type": "indicator"
}
```

### Use Cases

- Display boolean states (on/off, true/false)
- Warning lights and alerts
- Status indicators

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `dataSource` | string | ✅ Yes | - | Data source to monitor |
| `onColor` | string | ❌ No | "#00FF00" | Color when ON (hex) |
| `offColor` | string | ❌ No | "#2A2A2A" | Color when OFF (hex) |
| `imageOn` | string | ❌ No | - | Image path for ON state |
| `imageOff` | string | ❌ No | - | Image path for OFF state |
| `blinkWhenOn` | boolean | ❌ No | false | Blink/flash when ON |
| `blinkRate` | integer | ❌ No | 500 | Blink rate in milliseconds |
| `threshold` | number | ❌ No | 0.5 | Threshold for boolean conversion |

### Examples

**Simple LED Indicator:**
```json
{
  "id": "warning_led",
  "type": "indicator",
  "x": 350,
  "y": 50,
  "width": 20,
  "height": 20,
  "dataSource": "battery_percent",
  "threshold": 20,
  "onColor": "#FF0000",
  "offColor": "#2A2A2A",
  "blinkWhenOn": true,
  "blinkRate": 500,
  "showWhen": {
    "dataSource": "battery_percent",
    "operator": "<",
    "value": 20
  }
}
```

**Image-Based Indicator:**
```json
{
  "id": "status_indicator",
  "type": "indicator",
  "x": 340,
  "y": 120,
  "width": 30,
  "height": 30,
  "onColor": "#4CAF50",
  "offColor": "#F44336",
  "imageOn": "/assets/icons/check.png",
  "imageOff": "/assets/icons/cross.png"
}
```

---

## Speedometer Widget

Specialized speedometer/tachometer widget with realistic dial rendering.

### Type

```json
{
  "type": "speedometer"
}
```

### Use Cases

- Display vehicle speed
- Show motor RPM
- Any value needing a realistic dial gauge

### Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `dataSource` | string | ✅ Yes | - | Data source to display |
| `minValue` | number | ❌ No | 0 | Minimum dial value |
| `maxValue` | number | ❌ No | 120 | Maximum dial value |
| `units` | string | ❌ No | "km/h" | Unit label |
| `redZoneStart` | number | ❌ No | - | Start of red zone (high value warning) |
| `dialColor` | string | ❌ No | "#1A1A1A" | Dial background color (hex) |
| `needleColor` | string | ❌ No | "#00FFFF" | Needle color (hex) |
| `redZoneColor` | string | ❌ No | "#FF0000" | Red zone color (hex) |
| `showDigitalDisplay` | boolean | ❌ No | true | Show digital readout in center |
| `digitalFontSize` | number | ❌ No | 48 | Digital display font size |

### Examples

**Speed Dial:**
```json
{
  "id": "speedometer",
  "type": "speedometer",
  "x": 50,
  "y": 150,
  "width": 300,
  "height": 300,
  "dataSource": "speed",
  "minValue": 0,
  "maxValue": 80,
  "units": "km/h",
  "redZoneStart": 70,
  "dialColor": "#1A1A1A",
  "needleColor": "#00FFFF",
  "redZoneColor": "#FF0000",
  "showDigitalDisplay": true,
  "digitalFontSize": 52
}
```

**RPM Tachometer:**
```json
{
  "id": "tachometer",
  "type": "speedometer",
  "x": 50,
  "y": 150,
  "width": 300,
  "height": 300,
  "dataSource": "motor_rpm",
  "minValue": 0,
  "maxValue": 10000,
  "units": "RPM",
  "redZoneStart": 8500,
  "needleColor": "#FFA500",
  "showDigitalDisplay": true
}
```

---

## Common Patterns

### Data Binding

All widgets that support data sources can use the `dataSource` property:

```json
{
  "dataSource": "speed"
}
```

### Text Templates

Text widgets support placeholders:

```json
{
  "text": "Speed: {speed} km/h, Battery: {battery_percent}%"
}
```

### Conditional Visibility

Any widget can be shown/hidden based on conditions:

```json
{
  "showWhen": {
    "dataSource": "speed",
    "operator": ">",
    "value": 0
  }
}
```

### Layering

Use `zIndex` to control widget stacking:

```json
{
  "zIndex": 10  // Higher values appear on top
}
```

---

## Best Practices

### Performance

- **Limit widgets**: Keep under 30 widgets per screen
- **Graph windows**: Use 30-60 second time windows
- **Animations**: Use sparingly, especially blink animations

### Usability

- **Touch targets**: Buttons should be 44x44 pixels minimum
- **Font sizes**: Minimum 12px for readability
- **Contrast**: Ensure 4.5:1 contrast ratio for text

### Design

- **Consistency**: Use consistent colors and fonts
- **Hierarchy**: Use size and color to establish visual hierarchy
- **Spacing**: Leave adequate margins (10-20px)

---

## Support

**Documentation:**
- [JSON Schema Reference](JSON_SCHEMA.md)
- [Data Sources Guide](DATA_SOURCES.md)

**Examples:**
- [examples/simple_dashboard.json](../examples/simple_dashboard.json)
- [examples/advanced_dashboard.json](../examples/advanced_dashboard.json)
- [examples/simhub_style.json](../examples/simhub_style.json)

**GitHub:**
- [Issues](https://github.com/Normal99/veschub/issues)
- [Discussions](https://github.com/Normal99/veschub/discussions)

---

**Version:** 1.0  
**Last Updated:** January 2026  
**License:** MIT
