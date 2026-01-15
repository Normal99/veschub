# VescHub Dashboard Examples

This directory contains example dashboard configurations demonstrating various features and complexity levels of VescHub dashboards.

## Example Files

### 1. simple_dashboard.json

**Complexity:** ⭐ Beginner  
**Widgets:** 6  
**Screens:** 1

A basic dashboard perfect for getting started with VescHub. Features:

- Large speed display with units
- Battery percentage with conditional color formatting (red when low)
- Battery voltage display
- Trip distance tracking
- Clean, minimal design

**Best for:**
- First-time dashboard creators
- Learning the JSON schema basics
- Quick reference display

**Preview:**
```
┌──────────────────────────┐
│                          │
│      45.2 km/h           │  ← Speed (large, green)
│   CURRENT SPEED          │
│                          │
│        87%               │  ← Battery (conditional color)
│      BATTERY             │
│                          │
│       52.3V              │  ← Voltage
│                          │
│   Trip: 12.34 km         │  ← Trip distance
│                          │
└──────────────────────────┘
```

---

### 2. advanced_dashboard.json

**Complexity:** ⭐⭐⭐ Intermediate  
**Widgets:** 20+  
**Screens:** 3 (Main, Detailed, Graphs)

A multi-screen dashboard showcasing advanced features:

**Features:**
- Multiple screens with button navigation
- Speedometer widget with red zone
- Battery progress bar with gradient
- Multiple circular gauges (voltage, current, duty cycle)
- Real-time line graphs
- Conditional indicators and formatting
- Haptic feedback on button presses

**Screens:**
1. **Main** - Speedometer and battery bar
2. **Detailed** - Three gauges showing voltage, current, and duty cycle
3. **Graphs** - Real-time line graphs of speed and power usage

**Best for:**
- Learning multi-screen navigation
- Understanding gauge and graph widgets
- Implementing button actions

---

### 3. simhub_style.json

**Complexity:** ⭐⭐⭐⭐⭐ Advanced  
**Widgets:** 80+  
**Screens:** 6 (Home, Metrics, Analytics, Diagnostics, Info, Settings)

A comprehensive showcase of all VescHub features, inspired by SimHub dashboards:

**Features:**
- Professional multi-screen layout
- Custom theme with accent colors
- Navigation bar with 4 buttons
- Speedometer with digital display
- Battery panel with icon, percentage bar, and LED indicator
- Status indicator panel with multiple LEDs
- Real-time graphs (speed, power, temperature)
- Conditional formatting throughout
- Animations (blink, scale, fade)
- Shadows and gradients
- Diagnostic information
- Shape widgets for panels and decorations
- Custom background images
- Fault code display with conditional styling

**Screens:**
1. **Home** - Main dashboard with speedometer and battery panel
2. **Metrics** - Live gauges for current, temperature, and duty cycle
3. **Analytics** - Multiple real-time graphs
4. **Diagnostics** - System status indicators and fault codes
5. **Info** - About screen with logo and version info
6. **Settings** - Settings placeholder

**Best for:**
- Production dashboard reference
- Feature discovery
- Advanced techniques and patterns
- SimHub users transitioning to VescHub

---

## Using These Examples

### 1. Import into VescHub Mobile App

```bash
# Copy the JSON file to your device
# Then import via the app's dashboard manager
```

### 2. Edit in Web Editor

```javascript
// Load the JSON file in the web editor
// Customize widgets, colors, and layout
// Export when done
```

### 3. Hand-Edit the JSON

```bash
# Open in any text editor
nano examples/simple_dashboard.json

# Make changes
# Validate with schema
```

### 4. Validate Your Changes

```bash
# Using Python
python3 -m json.tool examples/simple_dashboard.json

# Using Node.js
node -e "JSON.parse(require('fs').readFileSync('examples/simple_dashboard.json'))"
```

---

## Customization Tips

### Starting from Simple Dashboard

1. **Change colors:**
   ```json
   "color": "#FF0000"  // Red
   "color": "#00FF00"  // Green
   "color": "#0000FF"  // Blue
   ```

2. **Adjust positions:**
   ```json
   "x": 100,  // Move right
   "y": 200   // Move down
   ```

3. **Change fonts:**
   ```json
   "fontSize": 48,
   "fontWeight": "bold"
   ```

### Adding Features from Advanced Dashboard

1. **Add a gauge:**
   - Copy a gauge widget from `advanced_dashboard.json`
   - Adjust position and size
   - Change `dataSource` to desired value

2. **Add screen navigation:**
   - Create a new screen
   - Add a button widget with `action.type: "switchScreen"`

3. **Add a graph:**
   - Copy a graph widget
   - Adjust `timeWindow` and `dataSeries`

---

## Common Modifications

### Change Units (km/h to mph)

1. Update text suffixes:
   ```json
   "suffix": " mph"
   ```

2. Adjust gauge ranges:
   ```json
   "maxValue": 60  // mph instead of km/h
   ```

3. Note: Unit conversion must be handled in the app

### Adjust Battery Thresholds

```json
{
  "conditionalFormatting": [
    {
      "condition": "battery_percent < 30",  // Change from 20
      "properties": { "color": "#FF0000" }
    }
  ]
}
```

### Change Theme Colors

1. Edit the theme object:
   ```json
   {
     "theme": {
       "accentColor": "#1E88E5",    // Blue
       "warningColor": "#FFC107",    // Amber
       "dangerColor": "#F44336"      // Red
     }
   }
   ```

2. Or override individual widget colors

---

## Learning Path

### Level 1: Beginner
1. Start with `simple_dashboard.json`
2. Change text, colors, and positions
3. Add/remove widgets
4. Experiment with conditional formatting

### Level 2: Intermediate
1. Study `advanced_dashboard.json`
2. Create multi-screen layouts
3. Add button navigation
4. Use gauges and progress bars

### Level 3: Advanced
1. Explore `simhub_style.json`
2. Implement complex conditional logic
3. Use animations and effects
4. Create custom themes
5. Build production-ready dashboards

---

## Validation

All example files are validated against the JSON schema:

```bash
# Install ajv-cli
npm install -g ajv-cli

# Validate examples
ajv validate -s ../schema/dashboard.schema.json -d simple_dashboard.json
ajv validate -s ../schema/dashboard.schema.json -d advanced_dashboard.json
ajv validate -s ../schema/dashboard.schema.json -d simhub_style.json
```

---

## Need Help?

- **Documentation:**
  - [JSON Schema Reference](../docs/JSON_SCHEMA.md)
  - [Widget Types Guide](../docs/WIDGET_TYPES.md)
  - [Data Sources Guide](../docs/DATA_SOURCES.md)

- **Community:**
  - [GitHub Issues](https://github.com/Normal99/veschub/issues)
  - [GitHub Discussions](https://github.com/Normal99/veschub/discussions)

- **Contributing:**
  - Share your custom dashboards!
  - Submit improvements to examples
  - Report issues or suggestions

---

**Happy Dashboard Building! 🎨🚀**
