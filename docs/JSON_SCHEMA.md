# VescHub JSON Schema Documentation

**Version:** 1.0  
**Last Updated:** January 2026

## Overview

This document describes the complete JSON schema for VescHub dashboard configurations. The schema is designed to be:

- **Human-readable**: Easy to hand-edit for beginners
- **Comprehensive**: Supports all widget types and customization options
- **Extensible**: Easy to add new widgets and properties
- **Production-ready**: Battle-tested schema for both mobile and web implementations

## Table of Contents

- [Dashboard Root Structure](#dashboard-root-structure)
- [Theme System](#theme-system)
- [Navigation](#navigation)
- [Screens](#screens)
- [Widgets](#widgets)
- [Common Widget Properties](#common-widget-properties)
- [Conditional Formatting](#conditional-formatting)
- [Animations](#animations)
- [Data Sources](#data-sources)
- [Version Management](#version-management)
- [Examples](#examples)

---

## Dashboard Root Structure

Every dashboard configuration must have the following root structure:

```json
{
  "version": "1.0",
  "name": "Dashboard Name",
  "description": "Optional description",
  "author": "Author Name",
  "defaultScreen": "screen_id",
  "theme": { },
  "navigation": { },
  "screens": [ ],
  "dataSources": { }
}
```

### Root Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `version` | string | ✅ Yes | Schema version (e.g., "1.0") |
| `name` | string | ✅ Yes | Dashboard name (1-100 characters) |
| `description` | string | ❌ No | Dashboard description (max 500 characters) |
| `author` | string | ❌ No | Dashboard author name |
| `defaultScreen` | string | ❌ No | ID of the screen to display on startup |
| `theme` | object | ❌ No | Global theme settings |
| `navigation` | object | ❌ No | Navigation configuration |
| `screens` | array | ✅ Yes | Array of screen objects (minimum 1) |
| `dataSources` | object | ❌ No | Custom data source definitions |

---

## Theme System

The theme object defines global styling defaults that can be overridden by individual widgets.

```json
{
  "theme": {
    "name": "Dark Mode",
    "defaultFontFamily": "Roboto",
    "defaultFontSize": 16,
    "defaultColor": "#FFFFFF",
    "defaultBackgroundColor": "#000000",
    "accentColor": "#00FF00",
    "warningColor": "#FFFF00",
    "dangerColor": "#FF0000"
  }
}
```

### Theme Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `name` | string | - | Theme name |
| `defaultFontFamily` | string | "Roboto" | Default font family |
| `defaultFontSize` | number | 16 | Default font size (8-200) |
| `defaultColor` | string | "#FFFFFF" | Default text color (hex) |
| `defaultBackgroundColor` | string | "#000000" | Default background color (hex) |
| `accentColor` | string | - | Accent color for highlights |
| `warningColor` | string | "#FFFF00" | Color for warnings |
| `dangerColor` | string | "#FF0000" | Color for danger/critical states |

**Color Format:** All colors must be in hex format: `#RRGGBB` or `#RRGGBBAA` (with alpha channel).

---

## Navigation

Configure how users navigate between screens.

```json
{
  "navigation": {
    "swipeEnabled": true,
    "swipeDirection": "horizontal",
    "buttonNavigation": true
  }
}
```

### Navigation Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `swipeEnabled` | boolean | true | Enable swipe gestures |
| `swipeDirection` | string | "horizontal" | Swipe direction: "horizontal" or "vertical" |
| `buttonNavigation` | boolean | true | Enable button-based navigation |

---

## Screens

Screens are individual pages in your dashboard. Users can navigate between screens using swipe gestures or buttons.

```json
{
  "screens": [
    {
      "id": "main",
      "name": "Main Screen",
      "backgroundColor": "#000000",
      "backgroundImage": "/assets/bg.png",
      "widgets": [ ],
      "_comment": "Optional comment about this screen"
    }
  ]
}
```

### Screen Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `id` | string | ✅ Yes | Unique screen identifier |
| `name` | string | ✅ Yes | Screen display name |
| `backgroundColor` | string | ❌ No | Background color (hex) |
| `backgroundImage` | string | ❌ No | Path to background image |
| `widgets` | array | ✅ Yes | Array of widget objects |
| `_comment` | string | ❌ No | Optional comment (not displayed) |

---

## Widgets

Widgets are the building blocks of your dashboard. Each widget has a type and a set of properties specific to that type.

### Supported Widget Types

1. **text** - Display static or dynamic text
2. **button** - Interactive button with images for different states
3. **gauge** - Circular or semicircular gauges
4. **graph** - Line or bar charts
5. **progressbar** - Horizontal or vertical progress bars
6. **image** - Static or dynamic images
7. **shape** - Basic shapes (rectangle, circle, line, polygon)
8. **indicator** - LED-style boolean indicators
9. **speedometer** - Specialized speedometer/tachometer widget

### Widget Example

```json
{
  "id": "speed_display",
  "type": "text",
  "x": 50,
  "y": 100,
  "width": 200,
  "height": 80,
  "dataSource": "speed",
  "text": "{speed}",
  "fontSize": 48,
  "color": "#00FF00",
  "suffix": " km/h",
  "decimals": 1
}
```

---

## Common Widget Properties

All widgets share these common properties:

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `id` | string | ✅ Yes | - | Unique widget identifier |
| `type` | string | ✅ Yes | - | Widget type (see list above) |
| `x` | number | ✅ Yes | - | X position in pixels |
| `y` | number | ✅ Yes | - | Y position in pixels |
| `width` | number | ✅ Yes | - | Width in pixels |
| `height` | number | ✅ Yes | - | Height in pixels |
| `rotation` | number | ❌ No | 0 | Rotation in degrees (0-360) |
| `opacity` | number | ❌ No | 1.0 | Opacity (0.0-1.0) |
| `visible` | boolean | ❌ No | true | Visibility flag |
| `zIndex` | integer | ❌ No | 0 | Z-index for layering |
| `dataSource` | string | ❌ No | - | Data source identifier |
| `showWhen` | object | ❌ No | - | Conditional visibility |
| `animation` | object | ❌ No | - | Animation settings |
| `conditionalFormatting` | array | ❌ No | - | Conditional formatting rules |
| `_comment` | string | ❌ No | - | Optional comment |

### Positioning

- **x, y**: Top-left corner position in pixels
- **width, height**: Widget dimensions in pixels
- **rotation**: Clockwise rotation in degrees (0-360)
- **zIndex**: Higher values appear on top of lower values

### Visibility

- **visible**: Set to `false` to hide the widget
- **showWhen**: Conditional visibility based on data values
- **opacity**: 0.0 (fully transparent) to 1.0 (fully opaque)

---

## Conditional Formatting

Apply different styling based on data values using the `conditionalFormatting` array:

```json
{
  "conditionalFormatting": [
    {
      "condition": "battery_percent < 20",
      "properties": {
        "color": "#FF0000",
        "fontSize": 52,
        "animation": {
          "type": "blink",
          "duration": 500,
          "repeat": true
        }
      }
    },
    {
      "condition": "speed > 50",
      "properties": {
        "color": "#FFFF00"
      }
    }
  ]
}
```

### Condition Format

Conditions are evaluated as JavaScript expressions. You can use:

- **Comparison operators**: `>`, `>=`, `<`, `<=`, `==`, `!=`
- **Logical operators**: `&&`, `||`, `!`
- **Data source names**: Reference any data source by name

**Examples:**
- `"battery_percent < 20"`
- `"speed > 80 && motor_temp < 60"`
- `"fault_code != 'NONE'"`

### Properties Override

Any widget property can be overridden when the condition is true. Common overrides:

- `color`, `backgroundColor`
- `fontSize`, `fontWeight`
- `fillColor`, `strokeColor`
- `opacity`, `visible`
- `animation`

---

## Animations

Add animations to widgets for visual feedback:

```json
{
  "animation": {
    "type": "blink",
    "duration": 500,
    "easing": "ease-in-out",
    "repeat": true,
    "repeatCount": -1
  }
}
```

### Animation Types

| Type | Description |
|------|-------------|
| `fade` | Fade in/out animation |
| `slide` | Slide animation |
| `scale` | Scale up/down animation |
| `rotate` | Rotation animation |
| `blink` | Blink/flash animation |

### Animation Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | string | - | Animation type (required) |
| `duration` | integer | 300 | Duration in milliseconds |
| `easing` | string | "ease-in-out" | Easing function |
| `repeat` | boolean | false | Whether to repeat |
| `repeatCount` | integer | 1 | Number of repeats (-1 for infinite) |

### Easing Functions

- `linear` - Constant speed
- `ease-in` - Slow start, fast end
- `ease-out` - Fast start, slow end
- `ease-in-out` - Slow start and end

---

## Data Sources

Data sources bind widgets to real-time VESC data. Reference data sources in widgets using the `dataSource` property.

### Built-in Data Sources

| Data Source | Type | Units | Description |
|-------------|------|-------|-------------|
| `speed` | float | km/h | Current speed |
| `battery_percent` | float | % | Battery percentage (0-100) |
| `battery_voltage` | float | V | Battery voltage |
| `motor_current` | float | A | Motor current (negative for regen) |
| `motor_temp` | float | °C | Motor temperature |
| `duty_cycle` | float | % | Motor duty cycle (0-100) |
| `amp_hours_used` | float | Ah | Total amp hours consumed |
| `odometer` | float | km | Total distance traveled |
| `trip_distance` | float | km | Current trip distance |
| `fault_code` | string | - | Active fault code |

### Custom Data Sources

Define custom data sources in the root `dataSources` object:

```json
{
  "dataSources": {
    "custom_value": {
      "type": "float",
      "units": "units",
      "description": "Description",
      "minValue": 0,
      "maxValue": 100,
      "defaultValue": 0
    }
  }
}
```

### Using Data Sources in Widgets

Reference data sources using curly braces in text:

```json
{
  "type": "text",
  "text": "Speed: {speed} km/h",
  "dataSource": "speed"
}
```

Or bind directly to a widget:

```json
{
  "type": "gauge",
  "dataSource": "motor_temp",
  "minValue": 0,
  "maxValue": 120
}
```

---

## Version Management

### Schema Versioning

The `version` field indicates the schema version:

```json
{
  "version": "1.0"
}
```

**Current Version:** 1.0

### Migration Path

When new schema versions are released:

1. Old dashboards continue to work (backward compatibility)
2. New features are opt-in
3. Migration guides are provided in release notes

### Future Versions

- **1.1**: Minor additions (new widget properties, data sources)
- **2.0**: Major changes (breaking changes, new widget types)

---

## Examples

### Minimal Dashboard

```json
{
  "version": "1.0",
  "name": "Minimal",
  "screens": [
    {
      "id": "main",
      "name": "Main",
      "widgets": [
        {
          "id": "speed",
          "type": "text",
          "x": 100,
          "y": 200,
          "width": 200,
          "height": 80,
          "dataSource": "speed",
          "text": "{speed}",
          "fontSize": 48,
          "suffix": " km/h"
        }
      ]
    }
  ]
}
```

### With Conditional Formatting

```json
{
  "id": "battery",
  "type": "text",
  "x": 50,
  "y": 100,
  "width": 300,
  "height": 60,
  "dataSource": "battery_percent",
  "text": "{battery_percent}%",
  "fontSize": 36,
  "color": "#00FF00",
  "conditionalFormatting": [
    {
      "condition": "battery_percent < 20",
      "properties": {
        "color": "#FF0000",
        "animation": {
          "type": "blink",
          "duration": 500,
          "repeat": true
        }
      }
    }
  ]
}
```

### Multi-Screen with Navigation

```json
{
  "version": "1.0",
  "name": "Multi-Screen",
  "defaultScreen": "main",
  "navigation": {
    "swipeEnabled": true,
    "buttonNavigation": true
  },
  "screens": [
    {
      "id": "main",
      "name": "Main",
      "widgets": [
        {
          "id": "nav_button",
          "type": "button",
          "x": 300,
          "y": 20,
          "width": 60,
          "height": 60,
          "imageUnpressed": "/assets/next.png",
          "imagePressed": "/assets/next_pressed.png",
          "action": {
            "type": "switchScreen",
            "target": "detail"
          }
        }
      ]
    },
    {
      "id": "detail",
      "name": "Detail",
      "widgets": []
    }
  ]
}
```

---

## Validation

### JSON Schema File

A formal JSON Schema file is available at `schema/dashboard.schema.json` for automated validation.

### Validation Tools

**Online Validators:**
- [JSONSchemaLint](https://jsonschemalint.com/)
- [JSON Schema Validator](https://www.jsonschemavalidator.net/)

**Command Line:**
```bash
# Using ajv-cli
npm install -g ajv-cli
ajv validate -s schema/dashboard.schema.json -d examples/simple_dashboard.json
```

---

## Best Practices

### 1. Naming Conventions

- **IDs**: Use descriptive snake_case: `speed_display`, `battery_gauge`
- **Screens**: Use simple lowercase names: `main`, `detailed`, `settings`
- **Data Sources**: Use snake_case: `motor_temp`, `battery_percent`

### 2. Layout

- **Screen Size**: Design for 400x640 (portrait) or 640x400 (landscape)
- **Touch Targets**: Buttons should be at least 44x44 pixels
- **Margins**: Leave 10-20px margins from screen edges

### 3. Performance

- **Widget Count**: Keep under 30 widgets per screen for best performance
- **Graphs**: Limit time window to 60 seconds for real-time graphs
- **Animations**: Use sparingly on mobile devices

### 4. Readability

- **Font Size**: Minimum 12px for readable text
- **Contrast**: Ensure sufficient contrast (WCAG AA: 4.5:1)
- **Color Blindness**: Use patterns/shapes in addition to color

### 5. Data Binding

- **Decimals**: Limit to 2 decimal places for most values
- **Units**: Always include units as suffix
- **Ranges**: Set appropriate min/max values for gauges

---

## Extensibility

### Adding New Widget Types

To add a new widget type:

1. Update `schema/dashboard.schema.json` with new type
2. Add widget-specific properties in schema
3. Document in `docs/WIDGET_TYPES.md`
4. Implement renderer in mobile/web apps

### Adding New Properties

To add properties to existing widgets:

1. Update JSON schema with new property
2. Set appropriate default values
3. Document in widget type documentation
4. Implement in renderer (backward compatible)

### Custom Data Sources

Applications can extend data sources:

```json
{
  "dataSources": {
    "gps_speed": {
      "type": "float",
      "units": "km/h",
      "description": "GPS-based speed"
    }
  }
}
```

---

## Support

**Full Documentation:**
- [Widget Types Reference](WIDGET_TYPES.md)
- [Data Sources Guide](DATA_SOURCES.md)
- [GitHub Repository](https://github.com/Normal99/veschub)

**Issues & Questions:**
- [GitHub Issues](https://github.com/Normal99/veschub/issues)
- [Discussions](https://github.com/Normal99/veschub/discussions)

---

**Schema Version:** 1.0  
**Last Updated:** January 2026  
**License:** MIT
