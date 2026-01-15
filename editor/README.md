# VescHub Dashboard Editor

A powerful, SimHub-inspired web-based dashboard editor for creating custom VESC controller dashboards. Build beautiful, data-driven dashboards visually in your browser, then export them to use on mobile devices.

## 🚀 Quick Start

1. **Open the editor**: Simply open `index.html` in a modern web browser
2. **No installation required**: The editor runs entirely in your browser
3. **Start creating**: Drag widgets from the left panel onto the canvas
4. **Configure**: Select widgets and edit their properties in the right panel
5. **Export**: Save your dashboard as JSON to use on mobile

## ✨ Features

### Visual Editor
- **Drag-and-drop interface**: Intuitive widget placement
- **Live preview**: See changes instantly as you edit
- **Grid & snapping**: Precise alignment with snap-to-grid
- **Zoom & pan**: Navigate large dashboards easily
- **Multi-select**: Edit multiple widgets at once
- **Undo/redo**: Full history with 50-level undo stack

### Widget Library
9 professional widget types:
- **Text**: Display static or dynamic text with full typography control
- **Gauge**: Circular/semicircular gauges with color zones
- **Speedometer**: Specialized speed/RPM dials
- **Progress Bar**: Horizontal/vertical bars with gradients
- **Graph**: Real-time line/bar charts
- **Button**: Interactive buttons with screen navigation
- **Indicator**: LED-style boolean indicators
- **Image**: Static or dynamic images
- **Shape**: Rectangles, circles, lines for layout

### Data Binding
- **16+ VESC data sources**: Speed, battery, current, temperature, etc.
- **Live data preview**: Mock data simulator for testing
- **Conditional formatting**: Change appearance based on values
- **Calculated fields**: Support for custom data sources

### Professional Tools
- **Alignment tools**: Align left, center, right, top, middle, bottom
- **Distribution**: Evenly space widgets horizontally or vertically
- **Z-order control**: Bring to front, send to back
- **Copy/paste/duplicate**: Fast workflow
- **Context menu**: Right-click for quick actions

### Multi-Screen Support
- **Multiple screens**: Create dashboard pages
- **Screen navigation**: Buttons can switch between screens
- **Screen manager**: Thumbnails, rename, duplicate, reorder

### Export & Import
- **Schema-compliant JSON**: Follows VescHub JSON schema
- **Validation**: Automatic schema validation on import
- **Example dashboards**: 4 pre-built examples to learn from
- **Local storage**: Auto-save and project management

## 🎮 Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+N` | New dashboard |
| `Ctrl+S` | Save dashboard |
| `Ctrl+E` | Export to JSON |
| `Ctrl+O` | Import JSON file |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Redo |
| `Ctrl+C` | Copy selected widget |
| `Ctrl+V` | Paste widget |
| `Ctrl+D` | Duplicate widget |
| `Delete` | Delete selected widget |
| `Ctrl+P` | Preview mode |
| `Arrow Keys` | Nudge widget position |
| `Shift+Arrow` | Nudge by 10 pixels |
| `Shift+Click` | Multi-select widgets |
| `Esc` | Clear selection |
| `F1` | Show help |

## 📖 Usage Guide

### Creating Your First Dashboard

1. **Start with a blank canvas**
   - Click "New" or open the editor for the first time
   - Choose your canvas size (phone, tablet, custom)

2. **Add widgets**
   - Drag a widget from the left panel onto the canvas
   - Position and resize as needed

3. **Configure widget properties**
   - Select the widget (click on it)
   - Edit properties in the right panel:
     - Position & Size (x, y, width, height)
     - Appearance (colors, fonts, styles)
     - Data Source (bind to VESC data)
     - Conditions (conditional formatting rules)

4. **Bind to data**
   - In the properties panel, select a data source
   - Add prefix/suffix for units (e.g., " km/h")
   - Set decimal places for numeric values

5. **Add conditional formatting**
   - Scroll to "Conditional Formatting" section
   - Click "Add Condition"
   - Set condition (e.g., "battery_percent < 20")
   - Define property changes (e.g., color: red)

6. **Create multiple screens**
   - Click "+" in the bottom screen panel
   - Switch between screens to edit each
   - Use button widgets to navigate between screens

7. **Test in preview mode**
   - Click "Preview" button or press `Ctrl+P`
   - Mock data will animate to simulate real usage
   - Test button actions and screen switching
   - Press "Exit Preview" to return to editing

8. **Export your dashboard**
   - Click "Export" button or press `Ctrl+E`
   - Download the JSON file
   - Use this file in the VescHub mobile app

### Widget-Specific Tips

#### Text Widget
- Use `{dataSource}` syntax for dynamic text
- Combine multiple data sources: `{speed} km/h | {battery_percent}%`
- Add conditional formatting for warnings

#### Gauge Widget
- Define color zones for visual feedback
- Set appropriate min/max values for your use case
- Use semicircular for compact displays

#### Graph Widget
- Add multiple data series to compare values
- Set time window (10s, 30s, 1m, etc.)
- Enable grid for easier reading

#### Button Widget
- Upload custom images for pressed/unpressed states
- Set action to "switchScreen" for navigation
- Enable haptic feedback for better UX

#### Progress Bar Widget
- Great for battery, temperature, or any percentage
- Use gradients for smooth color transitions
- Enable "Show Value" to display numeric value

### Example Dashboards

The editor includes 4 example dashboards you can load and learn from:

1. **Minimal Dashboard**
   - Simple speed and battery display
   - Great starting point for beginners

2. **Speed Dashboard**
   - Speedometer with digital display
   - RPM gauge
   - Power calculations
   - Perfect for racing

3. **Battery Monitor**
   - Battery percentage with progress bar
   - Voltage and current displays
   - Conditional formatting for low battery
   - LED indicators

4. **Comprehensive Dashboard**
   - Multi-screen example
   - All widget types demonstrated
   - Advanced conditional formatting
   - Button navigation between screens

**To load an example:**
1. Click "File" → "Load Example" in the toolbar
2. Choose an example dashboard
3. Explore and modify as needed

## 🎨 Design Best Practices

### Layout
- **Grid usage**: Enable grid for consistent alignment
- **Spacing**: Leave 10-20px margins from screen edges
- **Touch targets**: Make buttons at least 44x44 pixels
- **Visual hierarchy**: Use size and color to establish importance

### Colors
- **Contrast**: Ensure text is readable (4.5:1 contrast ratio)
- **Consistency**: Use theme colors for unified look
- **Color blindness**: Don't rely solely on color, use shapes/patterns too
- **Dark backgrounds**: Better for mobile displays and battery life

### Data Display
- **Units**: Always include units (km/h, °C, %, V, A)
- **Decimals**: 0-2 decimal places for most values
- **Ranges**: Set realistic min/max values for gauges
- **Warnings**: Use conditional formatting for critical values

### Performance
- **Widget count**: Keep under 30 widgets per screen
- **Animations**: Use sparingly on mobile
- **Graph windows**: Limit to 30-60 seconds for real-time graphs
- **Update rates**: Match widget update needs (text: high, graphs: medium)

## 🔧 Technical Details

### Browser Compatibility
- **Chrome/Edge**: ✅ Fully supported (recommended)
- **Firefox**: ✅ Fully supported
- **Safari**: ✅ Supported (iOS 13+)
- **Opera**: ✅ Supported

### Dependencies
- **Fabric.js 5.3.0**: Canvas rendering and object manipulation
- **Vanilla JavaScript**: No heavy frameworks required
- **LocalStorage**: For saving projects (5MB typical quota)

### File Structure
```
editor/
├── index.html          # Main HTML file
├── css/
│   ├── style.css       # Base styles and theme
│   ├── editor.css      # Editor layout styles
│   └── widgets.css     # Widget-specific styles
├── js/
│   ├── app.js          # Main application logic
│   ├── canvas.js       # Canvas management
│   ├── widgets.js      # Widget rendering
│   ├── properties.js   # Property panel
│   ├── export.js       # Export/import functionality
│   ├── storage.js      # LocalStorage management
│   └── utils.js        # Helper functions
├── assets/
│   ├── icons/          # UI icons
│   ├── examples/       # Example dashboards
│   └── fonts/          # Custom fonts
└── README.md           # This file
```

### JSON Schema
All exported dashboards follow the VescHub JSON schema defined in `/schema/dashboard.schema.json`. See `/docs/JSON_SCHEMA.md` for detailed documentation.

### Data Sources
16+ built-in VESC data sources:
- `speed` - Current speed (km/h)
- `battery_percent` - Battery percentage (0-100%)
- `battery_voltage` - Battery voltage (V)
- `motor_current` - Motor current (A)
- `motor_temp` - Motor temperature (°C)
- `duty_cycle` - Motor duty cycle (0-100%)
- And more... (see Data Sources panel)

## 💾 Storage & Auto-Save

### Auto-Save
- Saves every 30 seconds automatically
- Recovers unsaved work on restart
- Shows "Unsaved changes" indicator

### Project Management
- Save multiple dashboard projects
- Quick access to recent projects
- Export/import entire project library
- Storage usage indicator

### LocalStorage Limits
- Typical quota: ~5MB
- Monitor usage in Storage Info
- Delete old projects if needed
- Export backup before clearing

## 🚨 Troubleshooting

### Canvas not loading
- **Check console**: Open browser DevTools (F12)
- **Fabric.js CDN**: Ensure CDN is accessible
- **Clear cache**: Try Ctrl+F5 to hard refresh

### Widgets not draggable
- **Selection**: Ensure widget is selected (click on it)
- **Layer order**: Check if widget is behind another
- **Lock status**: Verify widget isn't locked

### Export fails
- **Validation errors**: Check console for specific issues
- **Required fields**: Ensure all required widget properties are set
- **Data sources**: Verify data source names are valid

### Storage quota exceeded
- **Delete old projects**: Remove unused projects
- **Export backup**: Save projects as JSON files
- **Clear auto-save**: Delete auto-save data
- **Use export instead**: Download JSON files instead of storing locally

### Performance issues
- **Widget count**: Reduce number of widgets per screen
- **Animations**: Disable animations if sluggish
- **Grid**: Disable grid if not needed
- **Browser**: Try different browser or update current one

## 🤝 Contributing

See the main repository [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:
- Reporting bugs
- Suggesting features
- Submitting pull requests
- Code style guidelines

## 📄 License

MIT License - see [LICENSE](../LICENSE) for details

## 🙏 Acknowledgments

- **SimHub**: Inspiration for the editor design and workflow
- **Fabric.js**: Powerful canvas library
- **VESC Community**: For amazing open-source motor controller technology
- **Contributors**: Everyone who helps improve VescHub

## 📞 Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/Normal99/veschub/issues)
- **Discussions**: [Ask questions and share dashboards](https://github.com/Normal99/veschub/discussions)
- **Documentation**: [Full docs](https://github.com/Normal99/veschub/tree/main/docs)

---

**Built with ❤️ for the VESC community**

**Version**: 1.0.0  
**Last Updated**: January 2026
