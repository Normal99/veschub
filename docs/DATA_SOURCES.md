# VescHub Data Sources Reference

**Version:** 1.0  
**Last Updated:** January 2026

## Overview

This document describes all available data sources for VescHub dashboards, including VESC telemetry data, calculated values, and how to create custom data sources.

## Table of Contents

1. [Built-in VESC Data Sources](#built-in-vesc-data-sources)
2. [Data Binding](#data-binding)
3. [Custom Data Sources](#custom-data-sources)
4. [Data Formatting](#data-formatting)
5. [Calculated Fields](#calculated-fields)
6. [Mock Data](#mock-data)
7. [Best Practices](#best-practices)

---

## Built-in VESC Data Sources

VescHub provides real-time access to VESC controller telemetry data through these built-in data sources:

### Speed & Motion

#### `speed`
- **Type:** float
- **Units:** km/h
- **Range:** 0 - 100+ (depending on vehicle)
- **Description:** Current vehicle speed
- **Update Rate:** 10-20 Hz
- **Example Usage:**
  ```json
  {
    "type": "text",
    "dataSource": "speed",
    "text": "{speed}",
    "suffix": " km/h",
    "decimals": 1
  }
  ```

#### `trip_distance`
- **Type:** float
- **Units:** km
- **Range:** 0+
- **Description:** Distance traveled in current trip
- **Reset:** Manual reset via app
- **Example Usage:**
  ```json
  {
    "type": "text",
    "dataSource": "trip_distance",
    "text": "Trip: {trip_distance}",
    "suffix": " km",
    "decimals": 2
  }
  ```

#### `odometer`
- **Type:** float
- **Units:** km
- **Range:** 0+
- **Description:** Total distance traveled (lifetime)
- **Persistence:** Stored in VESC memory
- **Example Usage:**
  ```json
  {
    "type": "text",
    "dataSource": "odometer",
    "text": "{odometer}",
    "suffix": " km",
    "decimals": 1
  }
  ```

---

### Battery

#### `battery_percent`
- **Type:** float
- **Units:** %
- **Range:** 0 - 100
- **Description:** Battery state of charge percentage
- **Calculation:** Based on voltage and battery chemistry
- **Example Usage:**
  ```json
  {
    "type": "progressbar",
    "dataSource": "battery_percent",
    "fillColor": "#00FF00",
    "conditionalFormatting": [
      {
        "condition": "battery_percent < 20",
        "properties": { "fillColor": "#FF0000" }
      }
    ]
  }
  ```

#### `battery_voltage`
- **Type:** float
- **Units:** V (Volts)
- **Range:** 0 - 100+ (depending on battery pack)
- **Description:** Current battery voltage
- **Update Rate:** 10-20 Hz
- **Example Usage:**
  ```json
  {
    "type": "gauge",
    "dataSource": "battery_voltage",
    "minValue": 40,
    "maxValue": 60,
    "units": "V"
  }
  ```

#### `amp_hours_used`
- **Type:** float
- **Units:** Ah (Amp hours)
- **Range:** 0+
- **Description:** Total amp hours consumed
- **Reset:** Manual reset via app
- **Example Usage:**
  ```json
  {
    "type": "text",
    "dataSource": "amp_hours_used",
    "text": "Used: {amp_hours_used}",
    "suffix": " Ah",
    "decimals": 2
  }
  ```

---

### Motor

#### `motor_current`
- **Type:** float
- **Units:** A (Amperes)
- **Range:** -100 to +200 (negative = regenerative braking)
- **Description:** Motor current draw
- **Note:** Negative values indicate regenerative braking
- **Example Usage:**
  ```json
  {
    "type": "gauge",
    "dataSource": "motor_current",
    "minValue": -50,
    "maxValue": 100,
    "zones": [
      {
        "from": -50,
        "to": 0,
        "color": "#00FF00",
        "label": "Regen"
      },
      {
        "from": 0,
        "to": 60,
        "color": "#1E88E5",
        "label": "Normal"
      },
      {
        "from": 60,
        "to": 100,
        "color": "#FF0000",
        "label": "High"
      }
    ]
  }
  ```

#### `motor_temp`
- **Type:** float
- **Units:** °C (Celsius)
- **Range:** -20 to 150
- **Description:** Motor temperature
- **Warning:** Monitor for overheating (>80°C)
- **Example Usage:**
  ```json
  {
    "type": "text",
    "dataSource": "motor_temp",
    "text": "{motor_temp}",
    "suffix": "°C",
    "decimals": 1,
    "conditionalFormatting": [
      {
        "condition": "motor_temp > 80",
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

#### `duty_cycle`
- **Type:** float
- **Units:** %
- **Range:** 0 - 100
- **Description:** Motor duty cycle percentage
- **Note:** Higher values = more power usage
- **Example Usage:**
  ```json
  {
    "type": "gauge",
    "dataSource": "duty_cycle",
    "gaugeType": "semicircular",
    "minValue": 0,
    "maxValue": 100,
    "units": "%"
  }
  ```

---

### System

#### `fault_code`
- **Type:** string
- **Values:** "NONE", "OVER_VOLTAGE", "UNDER_VOLTAGE", "DRV", "ABS_OVER_CURRENT", "OVER_TEMP_FET", "OVER_TEMP_MOTOR", etc.
- **Description:** Active fault code from VESC
- **Example Usage:**
  ```json
  {
    "type": "text",
    "dataSource": "fault_code",
    "text": "{fault_code}",
    "fontSize": 18,
    "color": "#4CAF50",
    "conditionalFormatting": [
      {
        "condition": "fault_code != 'NONE'",
        "properties": {
          "color": "#FF0000",
          "fontSize": 24,
          "fontWeight": "bold"
        }
      }
    ]
  }
  ```

---

## Data Binding

### Basic Binding

Bind a widget to a data source using the `dataSource` property:

```json
{
  "type": "text",
  "dataSource": "speed",
  "text": "{speed}",
  "suffix": " km/h"
}
```

### Template Syntax

Use curly braces `{}` to embed data source values in text:

```json
{
  "type": "text",
  "text": "Speed: {speed} km/h | Battery: {battery_percent}%"
}
```

### Multiple Data Sources

A single widget can reference multiple data sources in its text:

```json
{
  "type": "text",
  "text": "{speed} km/h\n{motor_temp}°C\n{battery_percent}%"
}
```

---

## Custom Data Sources

Define custom data sources in the dashboard root configuration:

```json
{
  "version": "1.0",
  "name": "My Dashboard",
  "dataSources": {
    "custom_value": {
      "type": "float",
      "units": "units",
      "description": "Custom data source",
      "minValue": 0,
      "maxValue": 100,
      "defaultValue": 0
    }
  },
  "screens": [...]
}
```

### Custom Data Source Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | string | ✅ Yes | Data type: "float", "integer", "string", "boolean" |
| `units` | string | ❌ No | Unit of measurement |
| `description` | string | ❌ No | Human-readable description |
| `minValue` | number | ❌ No | Minimum expected value |
| `maxValue` | number | ❌ No | Maximum expected value |
| `defaultValue` | any | ❌ No | Default value |

### Example: GPS Speed

```json
{
  "dataSources": {
    "gps_speed": {
      "type": "float",
      "units": "km/h",
      "description": "GPS-based speed measurement",
      "minValue": 0,
      "maxValue": 150,
      "defaultValue": 0
    }
  }
}
```

### Example: Custom Calculated Field

```json
{
  "dataSources": {
    "power_watts": {
      "type": "float",
      "units": "W",
      "description": "Power consumption (V × A)",
      "minValue": 0,
      "maxValue": 5000
    }
  }
}
```

---

## Data Formatting

### Decimal Places

Control decimal precision using the `decimals` property:

```json
{
  "type": "text",
  "dataSource": "speed",
  "text": "{speed}",
  "decimals": 1  // Shows: 45.2
}
```

```json
{
  "type": "text",
  "dataSource": "battery_percent",
  "text": "{battery_percent}",
  "decimals": 0  // Shows: 87
}
```

### Prefix and Suffix

Add text before or after values:

```json
{
  "type": "text",
  "dataSource": "speed",
  "text": "{speed}",
  "prefix": "Speed: ",
  "suffix": " km/h",
  "decimals": 1
  // Displays: "Speed: 45.2 km/h"
}
```

### Units

Display units with gauges and other widgets:

```json
{
  "type": "gauge",
  "dataSource": "motor_temp",
  "units": "°C",
  "minValue": 0,
  "maxValue": 120
}
```

---

## Calculated Fields

While VescHub doesn't yet support formula-based calculations in the JSON schema, you can prepare calculated data in the application layer.

### Common Calculations

#### Power (Watts)
```
power_watts = battery_voltage × motor_current
```

#### Energy Efficiency (Wh/km)
```
efficiency = (amp_hours_used × battery_voltage) / trip_distance
```

#### Range Estimate (km)
```
range_estimate = (battery_percent / 100) × max_range
```

#### Average Speed (km/h)
```
average_speed = trip_distance / (trip_time_seconds / 3600)
```

---

## Mock Data

For development and testing, VescHub supports mock data generation.

### Mock Data Configuration

The mobile app includes a mock data service that simulates realistic VESC telemetry:

```dart
// Mock data generation (mobile app implementation)
{
  speed: random(0, 60),
  battery_percent: random(20, 100),
  battery_voltage: random(48, 54),
  motor_current: random(-10, 80),
  motor_temp: random(30, 75),
  duty_cycle: random(10, 85),
  amp_hours_used: random(0, 15),
  odometer: random(100, 5000),
  trip_distance: random(0, 50),
  fault_code: "NONE"
}
```

### Testing with Mock Data

Mock data is useful for:
- ✅ Dashboard development without hardware
- ✅ Testing conditional formatting
- ✅ Verifying widget behavior
- ✅ Demonstrating features

---

## Best Practices

### 1. Data Source Naming

Use clear, descriptive names in snake_case:

```json
// ✅ Good
"dataSource": "motor_temp"
"dataSource": "battery_percent"

// ❌ Avoid
"dataSource": "temp"
"dataSource": "bat"
```

### 2. Units

Always include units for clarity:

```json
{
  "suffix": " km/h",  // Speed
  "suffix": "°C",     // Temperature
  "suffix": " V",     // Voltage
  "suffix": " A",     // Current
  "suffix": "%"       // Percentage
}
```

### 3. Decimal Precision

Choose appropriate decimal places:

```json
// Speed: 1 decimal
"decimals": 1  // 45.2 km/h

// Battery: no decimals
"decimals": 0  // 87%

// Energy: 2 decimals
"decimals": 2  // 12.34 Ah
```

### 4. Value Ranges

Set realistic min/max values for gauges:

```json
// Battery voltage (13S Li-ion)
{
  "minValue": 40,  // 3.08V per cell
  "maxValue": 54   // 4.15V per cell
}

// Motor temperature
{
  "minValue": 0,
  "maxValue": 120
}
```

### 5. Conditional Formatting

Use meaningful thresholds:

```json
// Battery warnings
{
  "condition": "battery_percent < 20",  // Low battery
  "properties": { "color": "#FF0000" }
}

// Temperature warnings
{
  "condition": "motor_temp > 80",  // Overheating
  "properties": { "color": "#FF0000" }
}
```

### 6. Update Rates

Be mindful of update frequencies:

- **High frequency** (10-20 Hz): speed, current, duty_cycle
- **Medium frequency** (1-5 Hz): temperature, voltage
- **Low frequency** (0.1-1 Hz): odometer, trip distance

---

## Data Source Reference Table

| Data Source | Type | Units | Range | Update Rate | Description |
|-------------|------|-------|-------|-------------|-------------|
| `speed` | float | km/h | 0-100+ | High | Current speed |
| `battery_percent` | float | % | 0-100 | Medium | Battery SoC |
| `battery_voltage` | float | V | 0-100+ | High | Battery voltage |
| `motor_current` | float | A | -100 to +200 | High | Motor current |
| `motor_temp` | float | °C | -20 to 150 | Medium | Motor temperature |
| `duty_cycle` | float | % | 0-100 | High | Motor duty cycle |
| `amp_hours_used` | float | Ah | 0+ | Low | Energy consumed |
| `odometer` | float | km | 0+ | Low | Total distance |
| `trip_distance` | float | km | 0+ | Low | Trip distance |
| `fault_code` | string | - | Various | Event | Active fault code |

---

## Condition Examples

### Speed-Based Conditions

```json
// Show warning above 80 km/h
{
  "condition": "speed > 80",
  "properties": { "color": "#FF0000" }
}

// Hide when stopped
{
  "showWhen": {
    "dataSource": "speed",
    "operator": ">",
    "value": 0
  }
}
```

### Battery-Based Conditions

```json
// Critical battery
{
  "condition": "battery_percent < 10",
  "properties": {
    "color": "#FF0000",
    "animation": { "type": "blink", "duration": 300 }
  }
}

// Low battery
{
  "condition": "battery_percent < 20",
  "properties": { "color": "#FFA500" }
}

// Normal battery
{
  "condition": "battery_percent >= 50",
  "properties": { "color": "#00FF00" }
}
```

### Temperature-Based Conditions

```json
// Hot motor
{
  "condition": "motor_temp > 80",
  "properties": { "color": "#FF0000" }
}

// Warm motor
{
  "condition": "motor_temp > 60 && motor_temp <= 80",
  "properties": { "color": "#FFA500" }
}
```

### Fault-Based Conditions

```json
// Fault detected
{
  "condition": "fault_code != 'NONE'",
  "properties": {
    "color": "#FF0000",
    "fontSize": 24,
    "fontWeight": "bold"
  }
}
```

---

## Future Enhancements

### Planned Data Sources

- `motor_rpm` - Motor RPM
- `controller_temp` - Controller/VESC temperature
- `throttle_position` - Throttle input percentage
- `brake_position` - Brake input percentage
- `watt_hours_used` - Energy consumption in Wh
- `watt_hours_regen` - Energy regenerated in Wh

### Calculated Fields

Future versions may support formula-based calculations:

```json
{
  "dataSources": {
    "power_watts": {
      "type": "calculated",
      "formula": "battery_voltage * motor_current",
      "units": "W"
    }
  }
}
```

---

## Support

**Documentation:**
- [JSON Schema Reference](JSON_SCHEMA.md)
- [Widget Types Guide](WIDGET_TYPES.md)

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
