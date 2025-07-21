# Technology Stack

## Framework & Language
- **Flutter** (>=3.1.0) - Cross-platform UI framework
- **Dart** (>=3.1.0) - Programming language

## State Management
- **flutter_riverpod** (^2.4.9) - Reactive state management

## Backend Services
- **Firebase Core** (^2.24.2) - Firebase initialization
- **Firebase Auth** (^4.15.3) - Authentication services
- **Cloud Firestore** (^4.13.6) - NoSQL database
- **Firebase Storage** (^11.5.6) - File storage

## Code Quality
- **flutter_lints** (^2.0.0) - Recommended linting rules
- **analysis_options.yaml** - Static analysis configuration

## Common Commands

### Development
```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run on specific platform
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS
flutter run -d windows     # Windows
flutter run -d macos       # macOS
flutter run -d linux       # Linux

# Hot reload during development
# Press 'r' in terminal or use IDE hot reload
```

### Building
```bash
# Build for web
flutter build web

# Build for Android
flutter build apk          # APK
flutter build appbundle    # App Bundle for Play Store

# Build for iOS
flutter build ios

# Build for desktop
flutter build windows
flutter build macos
flutter build linux
```

### Testing & Analysis
```bash
# Run tests
flutter test

# Analyze code
flutter analyze

# Check for outdated dependencies
flutter pub outdated

# Upgrade dependencies
flutter pub upgrade
```

### Maintenance
```bash
# Clean build cache
flutter clean

# Get dependencies after clean
flutter pub get
```