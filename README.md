# 🚀 VescHub

**A SimHub-inspired custom dashboard builder for VESC and Fardriver controllers**

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-early%20development-yellow.svg)](https://github.com/Normal99/veschub)

## 📖 Project Vision

VescHub is an open-source, cross-platform mobile app (iOS/Android) with a web-based editor for creating custom dashboards with live controller data. Inspired by SimHub's powerful dashboard customization capabilities, VescHub aims to bring that same level of flexibility and creativity to the VESC and Fardriver controller community.

**No hardware required for development!** VescHub uses mock data support, making it accessible for anyone to contribute regardless of whether they own a VESC or Fardriver controller.

## ✨ Key Features

- 📱 **Mobile-First Approach**: Native iOS and Android apps built with Flutter
- 🎨 **Visual Dashboard Editor**: Web-based drag-and-drop interface for creating custom dashboards
- 🔌 **Mock Data Support**: Develop and test without physical hardware
- 💾 **Export/Import Configs**: Share dashboard designs as JSON files
- 🔄 **Screen Switching**: Multiple dashboard pages with live data visualization
- 📡 **Future BLE Support**: Real-time data streaming from VESC/Fardriver controllers
- 🎯 **SimHub-Inspired**: Familiar workflow for SimHub users

## 🛠️ Tech Stack

- **Mobile App**: Flutter (single codebase for iOS/Android)
- **Editor**: Web-based (React, Vue.js, or vanilla JS - TBD)
- **Data Format**: JSON configuration files
- **Future**: Bluetooth Low Energy (BLE) for VESC communication
- **Version Control**: Git & GitHub

## 📊 Project Status

🟡 **Early Development/Planning Phase**

We're currently in the foundation stage, establishing the project structure, documentation, and core architecture. This is a perfect time to join and help shape the project!

## 🚦 Getting Started

> **Note**: Detailed setup instructions will be added as the project develops.

### Prerequisites

- For mobile development:
  - Flutter SDK (version TBD)
  - Android Studio / Xcode
  - Dart
- For web editor development:
  - Node.js and npm (version TBD)
  - Modern web browser

### Installation

```bash
# Clone the repository
git clone https://github.com/Normal99/veschub.git
cd veschub

# Mobile app setup (coming soon)
cd mobile
flutter pub get

# Web editor setup (coming soon)
cd editor
npm install
```

### Quick Start Guide

**🎨 Try the Dashboard Editor (Available Now!):**

1. Open `editor/index.html` in your web browser
2. Drag widgets from the left panel onto the canvas
3. Configure widget properties in the right panel
4. Bind widgets to VESC data sources
5. Export your dashboard as JSON

See the [Editor README](editor/README.md) for complete documentation.

**For other components:**

1. Check the [Roadmap](ROADMAP.md) to see current priorities
2. Read the [Contributing Guide](CONTRIBUTING.md) to get involved
3. Join discussions in GitHub Issues

## 📁 Repository Structure

```
veschub/
├── mobile/           # Flutter mobile app (iOS/Android) - Coming soon
├── editor/           # Web-based dashboard editor ✅ READY
│   ├── index.html    # Main editor interface
│   ├── css/          # Styling (dark theme)
│   ├── js/           # Application logic
│   ├── assets/       # Icons, examples, fonts
│   └── README.md     # Editor documentation
├── docs/             # Additional documentation
│   ├── JSON_SCHEMA.md      # Dashboard schema docs
│   ├── WIDGET_TYPES.md     # Widget reference
│   ├── DATA_SOURCES.md     # VESC data sources
│   └── PROJECT_STRUCTURE.md
├── examples/         # Example dashboard configurations
├── schema/           # JSON schema definition
├── LICENSE           # Project license
├── README.md         # This file
├── CONTRIBUTING.md   # Contribution guidelines
└── ROADMAP.md        # Project roadmap
```

## 🤝 Contributing

We welcome contributions from developers of all skill levels! Whether you're a beginner learning mobile/web development or an experienced developer, there's a place for you here.

See our [Contributing Guide](CONTRIBUTING.md) for details on:
- Ways to contribute
- Development workflow
- Code style guidelines
- How to submit pull requests

## 🗺️ Roadmap

Check out our [Roadmap](ROADMAP.md) for detailed information about:
- Current development phase
- Planned features
- Future enhancements
- Community-requested features

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- **SimHub**: Inspiration for the dashboard customization approach
- **VESC Community**: For building amazing open-source motor controller technology
- **Fardriver Community**: For innovative controller solutions
- All our contributors and supporters!

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/Normal99/veschub/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Normal99/veschub/discussions)

---

**Built with ❤️ by the open-source community**