# 🤝 Contributing to VescHub

First off, thank you for considering contributing to VescHub! 🎉

This is a **beginner-friendly, open-source project** where everyone is welcome. Whether you're making your first contribution or you're an experienced developer, we're excited to have you here!

## 💡 Ways to Contribute

There are many ways to contribute to VescHub:

### 🔨 Code Contributions
- **Mobile App Development**: Work on the Flutter mobile app for iOS/Android
- **Web Editor Development**: Build the dashboard editor interface
- **Widget Development**: Create new dashboard widgets and components
- **Bug Fixes**: Help squash bugs and improve stability

### 📚 Documentation
- Improve existing documentation
- Write tutorials and guides
- Create example dashboards
- Translate documentation

### 🧪 Testing & Quality Assurance
- Test features and report bugs
- Verify bug fixes
- Test on different devices and platforms
- Performance testing

### 💭 Ideas & Feedback
- Suggest new features
- Share dashboard design ideas
- Provide UX/UI feedback
- Share use cases and requirements

### 🎨 Design
- Create UI/UX designs for dashboards
- Design widget templates
- Create icons and graphics
- Improve visual consistency

## 🚀 Getting Started

### 1. Fork the Repository

Click the "Fork" button at the top right of the repository page to create your own copy.

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/veschub.git
cd veschub
```

### 3. Set Up Development Environment

#### For Mobile App Development (Flutter)

```bash
# Navigate to mobile directory (once created)
cd mobile

# Install dependencies
flutter pub get

# Run the app
flutter run
```

**Prerequisites:**
- Install Flutter SDK: https://flutter.dev/docs/get-started/install
- Install Android Studio or Xcode
- Set up an emulator or connect a physical device

#### For Web Editor Development

```bash
# Navigate to editor directory (once created)
cd editor

# Install dependencies
npm install

# Start development server
npm run dev
```

**Prerequisites:**
- Install Node.js and npm: https://nodejs.org/
- Modern web browser (Chrome, Firefox, Edge, Safari)

### 4. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Use descriptive branch names:
- `feature/add-gauge-widget`
- `fix/dashboard-loading-bug`
- `docs/update-installation-guide`

## 🔍 Finding Issues to Work On

1. **Check GitHub Issues**: Browse open issues at https://github.com/Normal99/veschub/issues
2. **Look for Labels**:
   - `good first issue` - Perfect for beginners
   - `beginner-friendly` - Suitable for new contributors
   - `help wanted` - We need help with these!
   - `documentation` - Documentation improvements
3. **Ask Questions**: If anything is unclear, comment on the issue or start a discussion

**Don't see an issue you want to work on?** Feel free to create a new one to discuss your idea!

## 🔄 Development Workflow

### 1. Make Your Changes

- Write clean, readable code
- Follow existing code patterns
- Add comments for complex logic
- Keep changes focused and minimal

### 2. Write Clear Commit Messages

```bash
git commit -m "Add speedometer gauge widget"
```

Good commit message examples:
- `Add speedometer gauge widget with configurable colors`
- `Fix dashboard layout bug on small screens`
- `Update installation instructions for Windows`

Avoid vague messages like:
- `Update stuff`
- `Fix bug`
- `Changes`

### 3. Test Your Changes

Before submitting:
- Test your changes thoroughly
- Verify existing features still work
- Test on different screen sizes (for mobile/web)
- Check for console errors or warnings

### 4. Push Your Changes

```bash
git push origin feature/your-feature-name
```

### 5. Submit a Pull Request

1. Go to your fork on GitHub
2. Click "Pull Request"
3. Fill out the PR template with:
   - Clear description of what your PR does
   - Reference to related issues (e.g., "Fixes #123")
   - Screenshots (for UI changes)
   - Testing steps

## 📋 Code Style Guidelines

### General Principles

- **Clarity over cleverness**: Write code that's easy to understand
- **Consistency**: Follow existing patterns in the codebase
- **Comments**: Explain *why*, not *what*
- **Small functions**: Keep functions focused and testable

### Dart (Flutter Mobile App)

```dart
// Use descriptive variable names
final double speedKmh = 45.5;

// Add comments for complex logic
/// Calculates the gauge angle based on speed value
/// Returns angle in degrees (0-270)
double calculateGaugeAngle(double speed, double maxSpeed) {
  return (speed / maxSpeed) * 270;
}

// Follow Dart style guide
class DashboardWidget extends StatelessWidget {
  const DashboardWidget({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Implementation
  }
}
```

### JavaScript (Web Editor)

```javascript
// Use const/let, not var
const maxSpeed = 100;
let currentSpeed = 0;

// Use clear function names
function updateDashboardWidget(widgetId, properties) {
  // Implementation
}

// Add JSDoc comments for public functions
/**
 * Exports dashboard configuration to JSON
 * @param {Object} dashboard - Dashboard configuration object
 * @returns {string} JSON string
 */
function exportDashboard(dashboard) {
  return JSON.stringify(dashboard, null, 2);
}
```

### Documentation

- Use Markdown for documentation files
- Include code examples where helpful
- Keep language clear and beginner-friendly
- Add emojis to make it friendly and scannable 😊

## 🎯 Pull Request Guidelines

### Before Submitting

- ✅ Code runs without errors
- ✅ Changes are tested
- ✅ Code follows style guidelines
- ✅ Commit messages are clear
- ✅ Branch is up to date with main

### PR Description Should Include

1. **What**: What does this PR do?
2. **Why**: Why is this change needed?
3. **How**: How does it work?
4. **Testing**: How did you test it?
5. **Screenshots**: Include for UI changes

### Example PR Description

```markdown
## What
Adds a circular gauge widget for displaying speed

## Why
Closes #15 - Users need a visual way to display speed data

## How
- Created GaugeWidget class in Flutter
- Implemented CustomPainter for gauge rendering
- Added configuration options for colors and ranges

## Testing
- Tested on Android emulator (Pixel 5)
- Tested on iOS simulator (iPhone 13)
- Verified with mock speed data (0-100 km/h)

## Screenshots
[Include screenshots here]
```

### After Submitting

- **Be responsive**: Reply to feedback promptly
- **Be open**: Be receptive to suggestions and changes
- **Be patient**: Reviews may take time
- **Ask questions**: If feedback is unclear, ask for clarification

## 💬 Communication Guidelines

### Be Respectful and Constructive

- Treat everyone with respect and kindness
- Give constructive feedback
- Assume positive intent
- Celebrate others' contributions

### Asking Questions

**There are no dumb questions!** If something is unclear:

- Ask in the GitHub issue
- Start a discussion
- Comment on the PR
- Reach out to maintainers

### Helping Others

- Answer questions when you can
- Review pull requests
- Share your knowledge
- Welcome new contributors

## 🌟 Recognition

Contributors will be recognized in:
- GitHub contributors list
- Project documentation
- Release notes

## 📜 Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards others

**Unacceptable behavior includes:**
- Harassment, trolling, or insulting comments
- Personal or political attacks
- Publishing others' private information
- Any conduct that could reasonably be considered inappropriate

### Enforcement

Project maintainers are responsible for clarifying standards and will take appropriate action in response to unacceptable behavior.

## 🎓 Learning Resources

### Flutter Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Codelabs](https://flutter.dev/docs/codelabs)

### Web Development Resources
- [MDN Web Docs](https://developer.mozilla.org/)
- [JavaScript.info](https://javascript.info/)
- [React Documentation](https://react.dev/) (if we choose React)

### Git & GitHub Resources
- [GitHub Guides](https://guides.github.com/)
- [Git Basics](https://git-scm.com/book/en/v2/Getting-Started-Git-Basics)

## 🆘 Need Help?

- **GitHub Issues**: Ask questions in issues
- **GitHub Discussions**: Start a discussion for broader topics
- **Documentation**: Check existing documentation

## 🙏 Thank You!

Every contribution, no matter how small, makes a difference. Thank you for being part of VescHub!

Happy coding! 🚀
