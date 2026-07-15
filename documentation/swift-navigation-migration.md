# Migrating a feature from Router to swift-navigation

This documents the pattern used to migrate the TorrentList feature
(`Packages/Torrent/Sources/TorrentUI/TorrentList`) off the `Router` package and
onto [swift-navigation](https://github.com/pointfreeco/swift-navigation), so the
same change can be repeated for other features still on `Router`.

Read [navigation.md](navigation.md) first for the Router-based pattern being
replaced.

## Remaining Router-based features (as of this writing)

- `Packages/Torrent/Sources/TorrentUI/Settings/Navigation` (`SettingsRouter`)
- `Packages/Torrent/Sources/TorrentUI/Onboarding/Navigation` (`TorrentOnboardingRouter`)
- `Sources/Magnesium/Features/Settings/Navigation` (`SettingsRouter`)
- `Sources/Magnesium/Features/Onboarding/Navigation` (`OnboardingRouter`)
- `Sources/Magnesium/Navigation` (`AppRouter`) — the app-level root router

Migrate leaf features first (Settings, Onboarding). Save `AppRouter` for last —
see "Routers with a parent" below, since it's the one other routers currently
attach to.

## Before you start: check for a `parent`

Grep the feature's `Router` file for how it's constructed. TorrentList's
`TorrentListRouter` was always constructed with no parent (`.init()`), so it
was a safe, isolated leaf to migrate. Some other routers **are** given a
parent, e.g. in `Sources/Magnesium/Navigation/AppSheet.swift`:

```swift
case .settings:
    SettingsFlow(router: SettingsRouter(router)) // `router` here is the AppRouter
```

`Routable`'s default `push`/`pop`/`popToRoot` implementations delegate to
`parent` when one is set (see `Router.swift` in the `Router` package checkout).
If the feature you're migrating has a non-nil parent, decide up front how that
relationship should be expressed post-migration — e.g. does popping the child
stack need to pop the parent's stack too? swift-navigation doesn't have a
built-in equivalent to `Routable`'s parent-delegation; you'd need to model it
explicitly (e.g. an `onPop` closure passed into the child's model, or having
the parent hold the child's `NavigationPath`/model and drive it directly).
This migration guide assumes a parentless (leaf) feature. If you hit a
parented one, stop and confirm the approach with the user before proceeding.

## The four files to collapse

A Router-based feature typically has, under `<Feature>/Navigation/`:

- `<Feature>Destination.swift` — push targets + a `RoutableDestinationViewModifier`
- `<Feature>Sheet.swift` — modal targets + a `RoutableSheetViewModifier`
- `<Feature>Error.swift` — error targets + a `RoutableErrorViewModifier` (may also
  carry unrelated `VisualError`/`Equatable` conformances bolted on — keep those,
  they're not part of the navigation system, just colocated)
- `<Feature>Router.swift` — the `Routable`-conforming class

Collapse these into **one file**, `<Feature>Model.swift`, containing:

1. An `@Observable final class <Feature>Model` with:
   - `var path: [Path] = []` (or a single unified enum if the feature's needs
     are simple — see "One enum vs two" below)
   - `var destination: Destination?` for error/modal presentation state
   - `push`, `pop`, `presentError`, `dismissError` methods (thin wrappers
     around the two properties above — no parent-delegation unless the
     feature has a parent, see above)
2. `@CasePathable` enums for `Path` (push destinations) and `Destination`
   (error/modal presentations), nested in an `extension <Feature>Model { ... }`
3. Any unrelated conformances that lived in the old `Error.swift` (e.g.
   `VisualError`, `Equatable` on a client error type) — keep as-is, just moved
   into this file.

Do **not** carry over `<Feature>DestinationModifier` / `<Feature>SheetModifier`
/ `<Feature>ErrorModifier` `ViewModifier` structs or their `withX(...)` `View`
extensions. Those move directly onto the Flow's `body` (see below) — a single
feature has exactly one `NavigationStack` and one error-panel presentation
site, so a dedicated `ViewModifier` + `View` extension per concern is pure
indirection once Router's multi-file convention is gone.

### One enum vs two

TorrentList ended up with two enums, `Path` (just `.detail`) and `Destination`
(`.clientError` / `.fileImportError`), because they're consumed by two
different SwiftUI modifiers (`.navigationDestination(for:)` vs `.panel(item:)`)
that each need an **exhaustive** switch over only their own cases. A single
merged enum forces dead `fatalError`/default branches in one modifier or the
other — avoid that. Keep push targets and modal/error targets in separate
`@CasePathable` enums, even though both live on the same model class.

## Wiring it into the Flow

The `<Feature>Flow` (the `Flow`-protocol-conforming — or, post-migration, plain
`View`-conforming — entry point) is where everything comes together. Example
shape (see `TorrentsListFlow.swift` for the full version):

```swift
public struct <Feature>Flow: View {
    @State public var model: <Feature>Model = .init()
    // ... other dependencies (session, preferences, etc.) ...

    public var body: some View {
        @Bindable var model = model

        NavigationStack(path: $model.path) {
            <Feature>RootView()
                .navigationDestination(for: <Feature>Model.Path.self) { destination in
                    switch destination {
                    case let .detail(thing):
                        DetailView(thing: thing)
                            .environment(model)
                    }
                }
        }
        .panel(item: $model.destination) { error in
            switch error {
            case let .clientError(error):
                ErrorPanelCard(error: error, primaryButtonAction: model.dismissError)
            // ... other cases ...
            }
        }
        .environment(model)
        // ... other .environment(...) injections ...
    }
}
```

Notes:
- `@Bindable var model = model` shadows the `@State` property so `$model` works
  inside `body` — this is the same pattern already used elsewhere in the
  codebase for `@Bindable` locals (e.g. `TorrentListView.swift`), so it's
  consistent with existing style, not swift-navigation-specific.
- If the feature doesn't use the `.panel(item:)` custom presentation (see
  `documentation/error_handling.md`) and instead needs a plain `.sheet(item:)`
  for its `Destination`/`Sheet` enum, the same pattern applies — one
  `.sheet(item: $model.destination)` block directly on the Flow, no separate
  modifier file.
- Every view inside the feature that used `@Environment(<Feature>Router.self)`
  becomes `@Environment(<Feature>Model.self)`. Call sites (`router.push(...)`,
  `router.presentError(...)`, `router.pop()`) rename to `model.*` with
  identical signatures — this is a pure find/replace, no call-site logic
  changes needed.

## Package dependency changes

Only touch the target(s) that own the feature being migrated — don't remove
the `Router` product from a target that still has other Router-based features
in it (e.g. `TorrentUI` will depend on both `Router` *and* `SwiftNavigation`/
`SwiftUINavigation` until every feature under it is migrated).

In the target's `Package.swift`:

```swift
.package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.4.1"),
```

And on the target itself:

```swift
.product(name: "SwiftNavigation", package: "swift-navigation"),
.product(name: "SwiftUINavigation", package: "swift-navigation"),
```

If the feature's `EntryPoint`/`SettingsFlow`/`OnboardingFlow` is constrained by
`MagnesiumFeatureModule`'s associated types to Router's `Flow` protocol
(`Packages/MagnesiumModule/Sources/MagnesiumModule/MagnesiumModule.swift`),
check whether that constraint has already been loosened to `View` (it was, for
`EntryPoint`, during the TorrentList migration). If you're migrating
`SettingsFlow` or `OnboardingFlow` next, that associated type will need the
same `: Flow` → `: View` change.

## Verifying the change

1. `xcodegen generate --spec project.yml` if you haven't already for this
   worktree.
2. Build the owning package directly first (fast feedback):
   `xcodebuild build -scheme <PackageProductName> -destination 'platform=iOS Simulator,id=<sim-id>'`
3. New macro dependencies (`SwiftNavigationMacros`, `CasePathsMacros`, and
   transitively `PerceptionMacros`) require a one-time interactive trust
   approval in Xcode.app the first time they're built in a given DerivedData
   — this cannot be done from the CLI/non-interactively. Ask the user to open
   the project in Xcode and click "Trust & Enable" if the build fails with
   `Macro "..." must be enabled before it can be used`.
4. Build and run the full `Magnesium` app scheme, not just the package, since
   that's what actually exercises the feature end-to-end.
5. Drive the feature on-device/simulator (RocketSim or manual) and confirm:
   push navigation, pop/back navigation, and error presentation (trigger a
   real error path, e.g. a bad server response) all still work.

## What NOT to change

- Don't touch other features' Router-based code in the same PR/session unless
  asked — migrate one feature at a time, same as the TorrentList change.
- Don't remove the `Router` package dependency from `Package.swift` until
  every feature in that target has been migrated off it.
- Don't invent parent-router semantics for a feature that doesn't need them —
  only add complexity here if the feature you're migrating actually had a
  non-nil parent under Router (see "Routers with a parent" above).
