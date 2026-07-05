# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

Magnesium is a multi-platform SwiftUI torrent client supporting iOS, tvOS, macOS, and visionOS (deployment target 26 across all platforms). It talks to remote torrent daemons (Deluge, qBittorrent) rather than downloading torrents itself.

The codebase is mid-migration from a monolithic app target into standalone Swift packages (see git history: "Continue migration to modules", "Start extracting UI portions", "Start reworking the App startup flow"). Expect some duplication and half-finished cleanup — see "Known In-Progress State" below before assuming something is dead code.

## Common Development Commands

### Project Generation
```bash
# Regenerate Magnesium.xcodeproj from project.yml — required after changing dependencies/targets
xcodegen generate --spec project.yml
```

### Building
```bash
# iOS Simulator
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=iOS Simulator,name=iPhone 16'

# macOS
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=macOS'

# tvOS Simulator
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=tvOS Simulator,name=Apple TV'

# visionOS Simulator
xcodebuild -project Magnesium.xcodeproj -scheme Magnesium -destination 'platform=visionOS Simulator,name=Apple Vision Pro'
```

### Testing
```bash
# App-level tests (Tests/, target: MagnesiumTests)
xcodebuild test -project Magnesium.xcodeproj -scheme MagnesiumTests -destination 'platform=iOS Simulator,name=iPhone 16'

# Single test class
xcodebuild test -project Magnesium.xcodeproj -scheme MagnesiumTests -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MagnesiumTests/StandardTorrentTests

# With test plan (coverage)
xcodebuild test -project Magnesium.xcodeproj -testPlan Magnesium.xctestplan -destination 'platform=iOS Simulator,name=iPhone 16'

# Quick sanity check
./test_setup.sh
```

Each local Swift package under `Packages/` has its own tests, runnable independently via SwiftPM, e.g.:
```bash
cd Packages/Torrent && swift test
cd Packages/Common && swift test
```

### Code Quality
```bash
# Format (120-char lines, tab indentation — see .swift-format)
swift-format format --in-place Sources/ Tests/ Packages/*/Sources Packages/*/Tests

# Lint (trailing_comma rule disabled — see .swiftlint.yml)
swiftlint
```

## Architecture

### Package layout

The app target (`Sources/Magnesium`) depends on three local SwiftPM packages under `Packages/` plus remote packages declared in `project.yml`:

- **`Packages/Common`** — cross-cutting utilities with no torrent-domain knowledge: `Keychain`/`SystemKeychain` abstractions, `Formatters`, `VisualError` protocol, `EnvironmentKeys`, and a `CommonUI` product (`Panel`/`PanelCard`, `ErrorView`) used for error presentation.
- **`Packages/MagnesiumModule`** — currently a near-empty scaffold module; other packages depend on it but it holds little logic yet.
- **`Packages/Torrent`** — the bulk of torrent domain logic and UI, split into fine-grained targets (see below). Exposes a single product, `TorrentUI`.

Remote dependencies (`project.yml` / `Packages/Torrent/Package.swift`): `Deluge-Swift`, `QBittorrent-Swift`, `Router` (custom navigation library), `ObservableDefaults`, `swift-log`, `sentry-cocoa`. `Deluge` and `QBittorrent` client packages are the same author's sibling repos.

### `Packages/Torrent` internal targets

Layered dependency chain, each target only depends on the ones below it:
```
TorrentUI
 ├─ TorrentManager ─ TorrentSession
 └─ TorrentSession ─ TorrentCore, TorrentPreferences, TorrentMapping (+ Deluge/QBittorrent clients)
      TorrentMapping ─ TorrentCore (+ Deluge/QBittorrent clients)
      TorrentPreferences ─ TorrentCore (+ ObservableDefaults)
      TorrentCore ─ Common
```
- **TorrentCore**: protocol-agnostic domain models (`StandardTorrent`, `StandardTorrentState`, `StandardLabel`, `TorrentServer`, filter/sort option types).
- **TorrentMapping**: converts wire-format models from the Deluge/qBittorrent client libraries into `StandardTorrent`/`StandardLabel` (see `Deluge/` and `qBittorrent/` subfolders and `TorrentMapper.swift`).
- **TorrentSession**: `TorrentSessionProtocol`/`TorrentClient` — abstracts an active connection to a specific daemon; `TorrentClientActing`-style protocol lets `Deluge`/`QBittorrent` implementations be swapped behind one interface.
- **TorrentPreferences**: persisted torrent-related settings (uses `ObservableDefaults`).
- **TorrentManager**: owns the live torrent collection, refresh timer, and torrent actions (pause/resume/delete), doing in-place updates so SwiftUI bindings survive refresh cycles.
- **TorrentUI**: all SwiftUI views/flows for onboarding, settings, and the torrent list/detail screens, each with its own `Navigation/` router (see Navigation System below).

### Navigation system (Router package)

Custom router-based navigation (external `Router` package, inspired by IceCubes App), documented in full in [documentation/navigation.md](documentation/navigation.md). Core shape:

- `RouterProtocol` defines `path` (push stack), `presentedSheet`, `presentedError`, and an optional `parent` router for hierarchical navigation.
- Every feature defines its own trio: `{Feature}Destinations` (push targets), `{Feature}Sheets` (modals), `{Feature}Errors` (error modals) — conforming to `RoutableDestination`/`RoutableSheet`/`RoutableError`.
- A `{Feature}Router` (`@Observable final class`) implements `RouterProtocol`; a `{Feature}Flow` view (conforming to the Router package's `Flow` protocol) wraps a `NavigationStack` bound to the router and injects it via `.environment(router)`.
- View modifiers (`Routable*ViewModifier`) wire up `.navigationDestination` / `.sheet` for each enum case.
- Each feature under `Sources/Magnesium/Features/*/Navigation/` and `Packages/Torrent/Sources/TorrentUI/*/Navigation/` follows this exact pattern — look at an existing one (e.g. `Sources/Magnesium/Features/Settings/Navigation/`) as the template before adding a new feature.

### Error handling

Documented in [documentation/error_handling.md](documentation/error_handling.md). Any error shown to the user must conform to `VisualError` (in `Packages/Common`), which supplies `title`/`systemName`/`subtitle` for presentation. User-facing errors are wrapped in a feature's `RoutableError` enum and rendered via `ErrorPanelCard`/`panel(item:)` inside that feature's error view modifier — always route errors through this mechanism rather than presenting ad hoc alerts.

### Dependency injection: `Current`

`Sources/Magnesium/Preferences/Environment.swift` defines `AppEnvironment` (torrent client factories, preferences, keychain, locale, calendar) and a global `Current` instance — mutable in `DEBUG` builds for test/dependency substitution, immutable in release. This file is explicitly marked `// TODO: remove all of this...` in-source — it's being phased out as more state moves into the package layer; don't extend it without checking whether the intended replacement already exists in `Packages/Torrent/Sources/TorrentSession` or `TorrentPreferences`.

### Known in-progress state

- `Sources/Magnesium/QBittorrent/` and `Sources/Magnesium/Views/` contain app-target copies of views that also exist under `Packages/Torrent/Sources/TorrentUI/Settings/QBittorrent/` and `.../Settings/`. Both are currently compiled into the `Magnesium` target (check `Magnesium.xcodeproj/project.pbxproj` / regenerate via `xcodegen` before assuming either copy is unused) — this is leftover duplication from the ongoing modularization, not two independent features.
- `AppFlow.swift` / `AppRouter` / `AppState` represent a newer app-startup rework (see git log "Start reworking the App startup flow"); prefer following these over older patterns if they conflict.

## Code Style

- **Formatting**: `swift-format`, 120-char lines, tab indentation (tab width 2), `OrderedImports` enabled — config in `.swift-format`.
- **Linting**: SwiftLint with `trailing_comma` disabled — config in `.swiftlint.yml`.
- Prefer functional style and existing patterns in the codebase over new abstractions; don't remove comments unless the change makes them inaccurate (see `.cursor/rules/swiftui.mdc`).

## Testing

Full conventions in [Tests/README.md](Tests/README.md). Highlights:

- Framework is **Swift Testing** (`@Suite`/`@Test`/`#expect`), not XCTest.
- Coverage targets: 95%+ models, 90%+ utilities, 85%+ business logic, 80%+ overall. Critical paths requiring 90%+: `StandardTorrent`, `TorrentMapper`, `TorrentManager`, `TorrentSession`.
- `Tests/Utilities/TestDataFactory.swift` is the standard way to construct test fixtures (`TestDataFactory.createStandardTorrent(...)`) — use it instead of hand-building models.
- `Tests/Mocks/` holds mocks for the client/session/keychain/timer/preferences layers; substitute these via `Current` (app target) rather than hitting real network/keychain in tests.
