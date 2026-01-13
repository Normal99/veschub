# 📂 VescHub Project Structure

This document provides a detailed overview of the VescHub project structure, explaining the organization of files and directories.

## 🏗️ Repository Organization

VescHub follows a **monorepo** structure, housing both the mobile app and web editor in a single repository. This approach offers several benefits:

- **Simplified dependency management**: Shared code and configurations
- **Atomic commits**: Changes across mobile and editor can be versioned together
- **Easier collaboration**: Everything in one place
- **Consistent tooling**: Shared CI/CD, linting, and documentation

## 📁 Root Directory Structure

```
veschub/
├── .github/                 # GitHub-specific files
│   ├── workflows/          # CI/CD workflow definitions
│   ├── ISSUE_TEMPLATE/     # Issue templates
│   └── PULL_REQUEST_TEMPLATE.md
│
├── mobile/                 # Flutter mobile application
│   ├── android/            # Android-specific files
│   ├── ios/                # iOS-specific files
│   ├── lib/                # Dart source code
│   ├── test/               # Unit and widget tests
│   ├── pubspec.yaml        # Flutter dependencies
│   └── README.md           # Mobile app documentation
│
├── editor/                 # Web-based dashboard editor
│   ├── public/             # Static assets
│   ├── src/                # Source code
│   ├── tests/              # Test files
│   ├── package.json        # Node.js dependencies
│   └── README.md           # Editor documentation
│
├── shared/                 # Shared code and resources (future)
│   ├── schemas/            # JSON schemas for configs
│   └── docs/               # Shared documentation
│
├── docs/                   # Project documentation
│   ├── PROJECT_STRUCTURE.md  # This file
│   ├── ARCHITECTURE.md     # System architecture (future)
│   ├── API.md              # API documentation (future)
│   └── guides/             # User and developer guides
│
├── examples/               # Example dashboard configurations
│   ├── basic/              # Simple example dashboards
│   ├── advanced/           # Complex example dashboards
│   └── templates/          # Dashboard templates
│
├── scripts/                # Utility scripts
│   ├── setup.sh            # Development setup script
│   └── build.sh            # Build automation
│
├── .gitignore              # Git ignore rules
├── LICENSE                 # Project license
├── README.md               # Main project README
├── CONTRIBUTING.md         # Contribution guidelines
└── ROADMAP.md              # Project roadmap
```

---

## 📱 Mobile App Structure (`/mobile`)

The Flutter mobile app follows the standard Flutter project structure with some custom organization.

### Directory Layout

```
mobile/
├── android/                    # Android platform files
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml
│   │   │   └── kotlin/         # Android-specific Kotlin code
│   │   └── build.gradle
│   └── gradle/
│
├── ios/                        # iOS platform files
│   ├── Runner/
│   │   ├── Info.plist
│   │   └── AppDelegate.swift   # iOS-specific Swift code
│   └── Runner.xcodeproj/
│
├── lib/                        # Main Dart source code
│   ├── main.dart              # App entry point
│   │
│   ├── config/                # Configuration
│   │   ├── app_config.dart
│   │   └── theme_config.dart
│   │
│   ├── models/                # Data models
│   │   ├── dashboard.dart
│   │   ├── widget.dart
│   │   └── vesc_data.dart
│   │
│   ├── screens/               # App screens/pages
│   │   ├── home_screen.dart
│   │   ├── dashboard_screen.dart
│   │   └── settings_screen.dart
│   │
│   ├── widgets/               # Reusable widgets
│   │   ├── dashboard/         # Dashboard-specific widgets
│   │   │   ├── gauge_widget.dart
│   │   │   ├── text_widget.dart
│   │   │   └── graph_widget.dart
│   │   └── common/            # Common UI widgets
│   │       ├── custom_button.dart
│   │       └── loading_indicator.dart
│   │
│   ├── services/              # Business logic and services
│   │   ├── dashboard_service.dart
│   │   ├── mock_data_service.dart
│   │   └── ble_service.dart   # Future: BLE connection
│   │
│   ├── utils/                 # Utility functions
│   │   ├── json_parser.dart
│   │   ├── validators.dart
│   │   └── constants.dart
│   │
│   └── state/                 # State management (Provider/Riverpod/Bloc)
│       ├── dashboard_provider.dart
│       └── app_state.dart
│
├── test/                      # Test files
│   ├── unit/                  # Unit tests
│   ├── widget/                # Widget tests
│   └── integration/           # Integration tests
│
├── assets/                    # Static assets
│   ├── images/
│   ├── fonts/
│   └── config/
│       └── example_dashboard.json
│
├── pubspec.yaml               # Flutter dependencies and assets
├── pubspec.lock               # Locked dependency versions
├── analysis_options.yaml      # Dart analyzer configuration
└── README.md                  # Mobile-specific documentation
```

### Key Files Explained

#### `main.dart`
Entry point of the Flutter app. Initializes the app, sets up routing, and configures themes.

#### `models/`
Contains data model classes representing:
- Dashboard configurations
- Widget definitions
- VESC/Fardriver data structures

#### `screens/`
Full-page screens/views in the app. Each screen is typically a separate Dart file.

#### `widgets/`
Reusable UI components. Dashboard widgets (gauge, text, graphs) are separate from common UI widgets (buttons, dialogs).

#### `services/`
Business logic layer:
- `dashboard_service.dart`: Dashboard loading, parsing, and rendering logic
- `mock_data_service.dart`: Generates mock controller data for testing
- `ble_service.dart`: (Future) Bluetooth communication with controllers

#### `pubspec.yaml`
Defines Flutter dependencies, assets, and configuration.

---

## 🖥️ Web Editor Structure (`/editor`)

The web editor structure will depend on the framework chosen (React, Vue, or Vanilla JS). Below is a generic structure that applies to most modern frameworks.

### Directory Layout (React Example)

```
editor/
├── public/                     # Static files served directly
│   ├── index.html
│   ├── favicon.ico
│   └── assets/
│       └── images/
│
├── src/                        # Source code
│   ├── index.js               # Entry point
│   ├── App.js                 # Root component
│   │
│   ├── components/            # React components
│   │   ├── Canvas/            # Dashboard canvas
│   │   │   ├── Canvas.js
│   │   │   ├── CanvasGrid.js
│   │   │   └── WidgetRenderer.js
│   │   │
│   │   ├── Toolbar/           # Editor toolbar
│   │   │   ├── Toolbar.js
│   │   │   └── ToolbarButton.js
│   │   │
│   │   ├── WidgetPalette/     # Widget selection palette
│   │   │   ├── WidgetPalette.js
│   │   │   └── WidgetCard.js
│   │   │
│   │   ├── PropertyEditor/    # Widget property editor
│   │   │   ├── PropertyEditor.js
│   │   │   ├── ColorPicker.js
│   │   │   └── NumberInput.js
│   │   │
│   │   └── common/            # Common components
│   │       ├── Button.js
│   │       ├── Modal.js
│   │       └── Input.js
│   │
│   ├── services/              # Business logic
│   │   ├── dashboardService.js
│   │   ├── exportService.js
│   │   └── validationService.js
│   │
│   ├── utils/                 # Utility functions
│   │   ├── jsonUtils.js
│   │   ├── geometryUtils.js
│   │   └── constants.js
│   │
│   ├── hooks/                 # Custom React hooks
│   │   ├── useDashboard.js
│   │   └── useDragAndDrop.js
│   │
│   ├── context/               # React context for state
│   │   ├── DashboardContext.js
│   │   └── EditorContext.js
│   │
│   ├── styles/                # CSS/styling
│   │   ├── global.css
│   │   ├── variables.css
│   │   └── components/
│   │
│   └── types/                 # TypeScript types (if using TS)
│       ├── dashboard.ts
│       └── widget.ts
│
├── tests/                     # Test files
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── package.json               # Node.js dependencies
├── package-lock.json          # Locked dependency versions
├── .eslintrc.js               # ESLint configuration
├── .prettierrc                # Prettier configuration
├── tsconfig.json              # TypeScript config (if using TS)
└── README.md                  # Editor-specific documentation
```

### Key Files Explained

#### `components/Canvas/`
The main dashboard editing canvas where widgets are placed and manipulated.

#### `components/WidgetPalette/`
Sidebar or panel showing available widgets that can be added to the dashboard.

#### `components/PropertyEditor/`
Panel for editing properties of selected widgets (color, position, data binding, etc.).

#### `services/`
Business logic for:
- Loading/saving dashboards
- Exporting to JSON
- Validating configurations

---

## 🔗 Shared Resources (`/shared`)

Future directory for code and resources shared between mobile and editor.

```
shared/
├── schemas/                   # JSON schema definitions
│   ├── dashboard_v1.schema.json
│   └── widget_v1.schema.json
│
├── types/                     # Shared type definitions
│   └── dashboard.types.ts
│
└── validators/                # Validation utilities
    └── schema_validator.js
```

---

## 📚 Documentation (`/docs`)

```
docs/
├── PROJECT_STRUCTURE.md       # This file
├── ARCHITECTURE.md            # System architecture
├── API.md                     # API reference
│
├── guides/                    # User and developer guides
│   ├── getting-started.md
│   ├── creating-widgets.md
│   ├── dashboard-config.md
│   └── ble-integration.md
│
└── design/                    # Design documents
    ├── ui-mockups/
    └── data-flow.md
```

---

## 🎨 Examples (`/examples`)

```
examples/
├── basic/                     # Simple examples
│   ├── speed-only.json
│   └── battery-monitor.json
│
├── advanced/                  # Complex examples
│   ├── racing-dashboard.json
│   └── diagnostic-panel.json
│
└── templates/                 # Starting templates
    ├── minimal.json
    └── full-featured.json
```

---

## 🛠️ Configuration Files

### `.gitignore`
Excludes build artifacts, dependencies, and IDE files from version control.

### `.github/workflows/`
CI/CD pipeline definitions:
- `mobile-ci.yml`: Flutter app testing and building
- `editor-ci.yml`: Web editor testing and building
- `docs.yml`: Documentation validation

---

## 📦 Build Outputs

### Mobile App Build Outputs

```
mobile/
├── build/                     # Build artifacts (not committed)
│   ├── app/
│   │   └── outputs/
│   │       └── apk/           # Android APK files
│   └── ios/
│       └── iphoneos/          # iOS build files
```

### Web Editor Build Outputs

```
editor/
├── build/                     # Production build (not committed)
│   ├── static/
│   ├── index.html
│   └── assets/
│
└── dist/                      # Alternative output directory
```

---

## 🔍 Where to Add New Components

### Adding a New Dashboard Widget (Mobile)

1. **Create widget file**: `mobile/lib/widgets/dashboard/my_widget.dart`
2. **Register widget**: Add to widget factory in `mobile/lib/services/dashboard_service.dart`
3. **Add tests**: Create `mobile/test/widget/my_widget_test.dart`
4. **Update documentation**: Document in `docs/guides/creating-widgets.md`

### Adding a New Feature to the Editor

1. **Create component**: `editor/src/components/MyFeature/MyFeature.js`
2. **Add to UI**: Import and use in parent component
3. **Add styling**: `editor/src/styles/components/MyFeature.css`
4. **Add tests**: Create `editor/tests/unit/MyFeature.test.js`

### Adding Example Dashboards

1. **Create JSON**: `examples/category/my-dashboard.json`
2. **Validate**: Ensure it follows the JSON schema
3. **Document**: Add description in `examples/README.md`
4. **Test**: Import in mobile app to verify it renders correctly

---

## 🚀 Development Workflow

### Setting Up Development Environment

1. **Clone repository**:
   ```bash
   git clone https://github.com/Normal99/veschub.git
   cd veschub
   ```

2. **Mobile setup**:
   ```bash
   cd mobile
   flutter pub get
   flutter run
   ```

3. **Editor setup**:
   ```bash
   cd editor
   npm install
   npm run dev
   ```

### Making Changes

1. **Create branch**: `git checkout -b feature/my-feature`
2. **Make changes** in appropriate directories
3. **Test locally**
4. **Commit**: `git commit -m "Add feature X"`
5. **Push**: `git push origin feature/my-feature`
6. **Open PR** on GitHub

---

## 🔐 Configuration Management

### Environment Variables

- **Mobile**: Configure in `.env` or `lib/config/app_config.dart`
- **Editor**: Use `.env` files (`.env.development`, `.env.production`)

### API Keys and Secrets

- **Never commit** secrets to version control
- Use environment variables or secure secret management
- Document required secrets in README files

---

## 📊 Asset Management

### Mobile Assets

Defined in `mobile/pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/config/
  fonts:
    - family: Roboto
      fonts:
        - asset: assets/fonts/Roboto-Regular.ttf
```

### Web Assets

Place in `editor/public/` for direct serving or `editor/src/assets/` for bundled assets.

---

## 🧪 Testing Structure

### Mobile Tests

```
mobile/test/
├── unit/                      # Unit tests
│   ├── models/
│   └── services/
├── widget/                    # Widget tests
│   └── dashboard/
└── integration/               # Integration tests
    └── dashboard_flow_test.dart
```

### Editor Tests

```
editor/tests/
├── unit/                      # Unit tests
│   ├── components/
│   └── services/
├── integration/               # Integration tests
└── e2e/                       # End-to-end tests
```

---

## 📈 Future Structure Changes

As the project grows, we may:

- Split mobile and editor into separate repositories
- Add separate packages for shared code
- Introduce a backend API service
- Add database for cloud features

---

## 🤝 Questions?

If you have questions about the project structure:
- Check existing documentation in `/docs`
- Open an issue with the `question` label
- Start a discussion in GitHub Discussions

---

**Last Updated**: January 2026
