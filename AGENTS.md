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

Remote dependencies (`project.yml` / `Packages/Torrent/Package.swift`): `Deluge-Swift`, `QBittorrent-Swift`, `swift-navigation` (`SwiftNavigation`/`SwiftUINavigation`, navigation — see Navigation System below), `ObservableDefaults`, `swift-log`, `sentry-cocoa`. `Deluge` and `QBittorrent` client packages are the same author's sibling repos. A handful of features not yet migrated off an older custom `Router` package still declare it as a dependency too — see Navigation System below.

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
- **TorrentUI**: all SwiftUI views/flows for onboarding, settings, and the torrent list/detail screens, using the swift-navigation pattern below. A few features haven't been migrated to it yet (see "Known in-progress state").

### Navigation system (swift-navigation)

Navigation uses [pointfreeco/swift-navigation](https://github.com/pointfreeco/swift-navigation) (`SwiftNavigation`/`SwiftUINavigation`), documented in full in [documentation/navigation.md](documentation/navigation.md). Use the **swift-navigation** skill for general library anti-patterns (the two-enum split, `Identifiable` payloads, item- vs. array-based navigation) when writing or reviewing this code. Core shape:

- Each view that owns navigation state defines its **own nested `Model`** (`@Observable final class`, usually named `Model`, nested as an `extension` on the owning view or Flow) — there is **no single shared `<Feature>Model.swift` file**. Examples:
  - `TorrentListView.Model` — nested directly in [TorrentListView.swift](Packages/Torrent/Sources/TorrentUI/TorrentList/TorrentListView.swift), used by the Flow at the top of the stack.
  - `TorrentSettingsFlow.TorrentSettingsModel`, `TorrentSettingsListView.Model`, `AddServerView.Model` — three separate, view-local models forming a multi-level push stack (list → add-a-server → add-new-server), each pushed view chaining its own `.navigationDestination(item:)` rather than one array-based `path` at the Flow root. Prefer this per-view-model chaining over `NavigationStack(path:)` + `.navigationDestination(for:)` when the "multi-level" need is really just "each screen pushes the next" — reserve the array/path form for when the same screen type can recur at arbitrary depth.
- Every model splits presentation state **by surface, not by feature**: a `destination` property (`@CasePathable enum Destination`) for push targets driving `.navigationDestination(item:)`, and a separate `error` property (`@CasePathable enum Error`) for modal/panel error state driving `.panel(item:)` (see Error handling below) — never one enum covering both. This keeps each presentation modifier's switch exhaustive over only its own cases, and means an error can appear without silently popping whatever's pushed, since the two are independent optionals.
- `Error` enum cases get `Identifiable` via `var id: Self { self }` on the enum itself rather than a wrapper type, since the cases are already `Hashable`.
- There are no `push`/`pop`/`presentError`/`dismissError` wrapper methods — call sites assign the model's property directly (`model.destination = .foo`, `model.destination = nil`).
- A small number of features haven't been migrated to this pattern yet and still use an older custom `Router` package — see "Known in-progress state" below and [documentation/swift-navigation-migration.md](documentation/swift-navigation-migration.md) for the migration checklist if you're converting one.

### Error handling

Documented in [documentation/error_handling.md](documentation/error_handling.md). Any error shown to the user must conform to `VisualError` (in `Packages/Common`), which supplies `title`/`systemName`/`subtitle` for presentation. User-facing errors are wrapped in a feature's `Error` enum (nested on that feature's `Model`, see Navigation System above) and rendered via `ErrorPanelCard`/`panel(item:)` — always route errors through this mechanism rather than presenting ad hoc alerts.

### Dependency injection: `Current`

`Sources/Magnesium/Preferences/Environment.swift` defines `AppEnvironment` (torrent client factories, preferences, keychain, locale, calendar) and a global `Current` instance — mutable in `DEBUG` builds for test/dependency substitution, immutable in release. This file is explicitly marked `// TODO: remove all of this...` in-source — it's being phased out as more state moves into the package layer; don't extend it without checking whether the intended replacement already exists in `Packages/Torrent/Sources/TorrentSession` or `TorrentPreferences`.

### Known in-progress state

- `Sources/Magnesium/QBittorrent/` and `Sources/Magnesium/Views/` contain app-target copies of views that also exist under `Packages/Torrent/Sources/TorrentUI/Settings/QBittorrent/` and `.../Settings/`. Both are currently compiled into the `Magnesium` target (check `Magnesium.xcodeproj/project.pbxproj` / regenerate via `xcodegen` before assuming either copy is unused) — this is leftover duplication from the ongoing modularization, not two independent features.
- `AppFlow.swift` / `AppRouter` / `AppState` represent a newer app-startup rework (see git log "Start reworking the App startup flow"); prefer following these over older patterns if they conflict.
- The navigation migration to swift-navigation (see Navigation System above) is partway through: `Packages/Torrent/Sources/TorrentUI/TorrentList` and `Packages/Torrent/Sources/TorrentUI/Settings` (the package-level copy) are done. `Packages/Torrent/Sources/TorrentUI/Onboarding`, `Sources/Magnesium/Features/Settings`, `Sources/Magnesium/Features/Onboarding`, and `Sources/Magnesium/Navigation` (`AppRouter`, the app-level root — migrate last) still use the older `Router` package. A feature with a `Navigation/` subdirectory is still on `Router`; one with a nested `Model` on its view/Flow has been migrated. Don't assume every feature follows the same navigation pattern — check first, and see [documentation/swift-navigation-migration.md](documentation/swift-navigation-migration.md) if converting one.

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
