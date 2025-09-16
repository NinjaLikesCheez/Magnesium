# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Common Development Commands

### Project Generation
```bash
# Generate Xcode project from project.yml (required after dependency changes)
xcodegen generate --spec project.yml
```

### Building
```bash
# Build for iOS Simulator
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=iOS Simulator,name=iPhone 16'

# Build for macOS
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=macOS'

# Build for tvOS Simulator  
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=tvOS Simulator,name=Apple TV'

# Build for visionOS Simulator
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

### Testing
```bash
# Run all tests
xcodebuild test -project Magnesium.xcodeproj -scheme MagnesiumTests -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test class
xcodebuild test -project Magnesium.xcodeproj -scheme MagnesiumTests -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MagnesiumTests/StandardTorrentTests

# Run with test plan (includes coverage)
xcodebuild test -project Magnesium.xcodeproj -testPlan Magnesium.xctestplan -destination 'platform=iOS Simulator,name=iPhone 16'

# Quick test setup validation
./test_setup.sh
```

### Code Quality
```bash
# Format code (120-char lines, tab indentation)
swift-format format --in-place Sources/ Tests/

# Lint code (trailing comma rule disabled)
swiftlint
```

## High-Level Architecture Overview

Magnesium is a multi-platform SwiftUI torrent client supporting iOS (18.4+), tvOS (18.4+), macOS (15.4+), and visionOS (2.0+). The app uses a layered architecture with clean separation of concerns:

### Core Architectural Patterns
- **Router-based Navigation**: Custom navigation system using destinations, sheets, and errors
- **Observable State Management**: SwiftUI's `@Observable` for reactive UI updates
- **Session Abstraction**: Protocol-based torrent client implementations (Deluge, QBittorrent)
- **Dependency Injection**: Environment-based dependency management via `Current`
- **Typed Error Handling**: `VisualError` protocol for user-facing error presentation
- **Comprehensive Testing**: Swift Testing framework with 80%+ coverage target

### Data Flow
1. **AppState** determines authentication status and routing
2. **Session** manages active server connection and client implementation
3. **TorrentManager** handles torrent CRUD operations and periodic updates
4. **Router** coordinates navigation between feature flows
5. **AppPreferences** persists user settings with keychain integration

## Key Architectural Components

### TorrentManager
- **Responsibility**: Manages torrent collection with delta-style updates for SwiftUI binding compatibility
- **Key Features**: Auto-refresh timer, filtered/sorted views, torrent actions (pause/resume/delete)
- **Location**: `Sources/Magnesium/TorrentManager.swift`

### Session & TorrentClientActing
- **Responsibility**: Abstracts torrent client implementations behind unified protocol
- **Supported Clients**: Deluge (implemented), QBittorrent (in progress)
- **Location**: `Sources/Magnesium/Models/Session/`
- **Pattern**: Factory method creates appropriate `TorrentClientActing` implementation

### Router System
- **Structure**: Each feature has its own router with typed destinations, sheets, and errors
- **Key Files**: 
  - `Sources/Magnesium/Features/*/Navigation/`
  - Router package: `Sources/Router/`
- **Pattern**: Hierarchical routers with parent-child relationships for complex flows

### StandardTorrent Model
- **Responsibility**: Observable torrent representation with computed properties
- **Key Features**: Progress formatting, speed calculations, state-dependent display logic
- **Update Pattern**: In-place updates preserve SwiftUI bindings during refresh cycles

### Environment & Current
- **Pattern**: Dependency injection via global `Current` variable
- **Components**: Torrent clients, preferences, keychain, locale, calendar
- **Testing**: Mutable in DEBUG builds for dependency substitution

### AppPreferences
- **Storage**: UserDefaults + SystemKeychain for sensitive data
- **Pattern**: Observable wrapper with automatic persistence
- **Location**: `Sources/Magnesium/Common/Preferences/`

## Development Practices

### Code Style
- **Line Length**: 120 characters (configured in `.swift-format`)
- **Indentation**: Tabs (width: 2 spaces)
- **SwiftLint**: Custom rules with `trailing_comma` disabled
- **Imports**: `OrderedImports` rule enabled

### Testing Strategy
- **Framework**: Swift Testing (not XCTest)
- **Coverage Targets**: 95%+ (models), 90%+ (utilities), 85%+ (business logic), 80%+ (overall)
- **Mock Strategy**: Comprehensive mocks in `Tests/Mocks/` directory
- **Test Data**: `TestDataFactory` for consistent test object creation
- **Critical Paths**: TorrentManager, TorrentMapper, Session management, StandardTorrent model

### Error Handling
- **User-Facing**: All user-visible errors must conform to `VisualError` protocol
- **Pattern**: Typed throwing functions with `RoutableError` for navigation integration
- **Documentation**: See `documentation/error_handling.md` for detailed patterns

### Navigation Patterns
- **System**: Custom router-based navigation (see `documentation/navigation.md`)
- **Structure**: Destinations (push), Sheets (modal), Errors (error modal)
- **Testing**: Router state is easily testable with simple assertions

### Cursor AI Rules
From `.cursor/rules/swiftui.mdc`:
- Expert-level Swift/SwiftUI development
- Maintainable, clean code with functional programming preference
- Latest SwiftUI features and interaction design focus
- Preserve existing implementations over creating new structures
- Comments preserved unless made irrelevant by changes