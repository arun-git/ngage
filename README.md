# Ngage Platform

A multi-platform engagement application built with Flutter for web, mobile, and desktop. Designed to support team-based competitions, events, and social interactions across corporate, educational, and community contexts.

## Features

- Cross-platform support (Web, Android, iOS, Windows, macOS, Linux)
- Team-based competitions and events
- Social interactions and engagement tools
- Firebase backend integration for authentication, database, and storage

## Getting Started

### Prerequisites

- Flutter SDK (>=3.1.0)
- Dart SDK (>=3.1.0)
- Firebase project with Firestore, Authentication, and Storage enabled

### Installation

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase using the Firebase CLI or manual setup
4. Run the app with `flutter run`

## Firebase Index Errors

When working with Firestore queries, you may encounter index errors that require creating a new composite index. The app includes a special error handling system that makes these errors selectable and provides direct links to create the required indexes.

### How to Handle Index Errors

1. When you see a Firebase index error, a dialog will appear with the error details
2. You can either:
   - Copy the error message and create the index manually in the Firebase console
   - Click the "Open Firebase Console" button to be taken directly to the index creation page
3. After creating the index, retry the operation that caused the error

### Example Index Error

```
FAILED_PRECONDITION: The query requires an index. You can create it here: https://console.firebase.google.com/project/your-project/firestore/indexes?create_index=...
```

## Development

### Project Structure

```
ngage/
├── lib/                   # Main Flutter source code
│   ├── main.dart          # Application entry point
│   ├── models/            # Data models and entities
│   ├── services/          # Business logic and external integrations
│   ├── repositories/      # Data access layer (Firebase interactions)
│   ├── ui/                # User interface components and screens
│   └── utils/             # Utility functions and helpers
├── test/                  # Unit and widget tests
└── pubspec.yaml           # Dependencies and project configuration
```

### Common Commands

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

# Build for web
flutter build web

# Run tests
flutter test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.