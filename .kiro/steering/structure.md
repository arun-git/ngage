# Project Structure

## Root Directory
```
ngage/
├── .kiro/                  # Kiro AI assistant configuration
│   ├── specs/             # Spec-driven development files
│   └── steering/          # AI assistant steering rules
├── lib/                   # Main Flutter source code
├── test/                  # Unit and widget tests
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
├── web/                   # Web-specific configuration
├── windows/               # Windows-specific configuration
├── macos/                 # macOS-specific configuration
├── linux/                 # Linux-specific configuration
├── pubspec.yaml           # Dependencies and project configuration
└── analysis_options.yaml  # Dart analyzer configuration
```

## Source Code Organization (`lib/`)

### Architecture Pattern
The project follows a **layered architecture** with clear separation of concerns:

```
lib/
├── main.dart              # Application entry point
├── models/                # Data models and entities
├── services/              # Business logic and external integrations
├── repositories/          # Data access layer (Firebase interactions)
├── ui/                    # User interface components and screens
└── utils/                 # Utility functions and helpers
```

### Layer Responsibilities

#### Models (`lib/models/`)
- Data classes and entities
- Serialization/deserialization logic
- Domain objects

#### Services (`lib/services/`)
- Business logic implementation
- External API integrations
- Complex operations and workflows

#### Repositories (`lib/repositories/`)
- Data access abstraction
- Firebase Firestore operations
- Firebase Storage operations
- Caching logic

#### UI (`lib/ui/`)
- Screens and pages
- Reusable widgets
- UI-specific logic
- Material Design 3 components

#### Utils (`lib/utils/`)
- Helper functions
- Constants
- Extensions
- Utility classes

## Naming Conventions
- **Files**: snake_case (e.g., `user_profile.dart`)
- **Classes**: PascalCase (e.g., `UserProfile`)
- **Variables/Functions**: camelCase (e.g., `getUserProfile`)
- **Constants**: SCREAMING_SNAKE_CASE (e.g., `MAX_RETRY_COUNT`)

## Import Organization
1. Dart core libraries
2. Flutter framework imports
3. Third-party package imports
4. Local project imports (relative paths)

## State Management
- Use **Riverpod** providers for state management
- Keep providers close to their usage context
- Separate business logic from UI logic through services layer