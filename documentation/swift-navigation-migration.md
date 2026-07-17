# Migrating a feature from Router to swift-navigation

This documents the pattern used to migrate the TorrentList and Settings
features (`Packages/Torrent/Sources/TorrentUI/TorrentList`,
`Packages/Torrent/Sources/TorrentUI/Settings`) off the `Router` package and
onto [swift-navigation](https://github.com/pointfreeco/swift-navigation), so
the same change can be repeated for other features still on `Router`.

Read [navigation.md](navigation.md) first for the (now deprecated) Router-based
pattern being replaced, and the **swift-navigation** skill
(`.claude/skills/swift-navigation/SKILL.md`) for general library anti-patterns
this doc doesn't repeat.

## Remaining Router-based features (as of this writing)

- `Packages/Torrent/Sources/TorrentUI/Onboarding/Navigation` (`TorrentOnboardingRouter`)
- `Sources/Magnesium/Features/Onboarding/Navigation` (`OnboardingRouter`)
- `Sources/Magnesium/Navigation` (`AppRouter`) — the app-level root router

Already migrated (reference these for the real pattern, not just this doc):
`Packages/Torrent/Sources/TorrentUI/TorrentList`,
`Packages/Torrent/Sources/TorrentUI/Settings` (the package-level copy), and
`Sources/Magnesium/Features/Settings` (the app-target shell — see
`SettingsListView.swift`; it had a non-nil parent, `AppRouter`, and its
`dismissSheet(withParent: true)`/`reset(withParent: true)` call sites became
plain `@Environment(\.dismiss)` calls since the feature is only ever
presented as a `.sheet`).

Migrate leaf features first (Onboarding next). Save `AppRouter` for last —
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

## Collapsing the Router files: no fixed file name, but a fixed shape

A Router-based feature typically has, under `<Feature>/Navigation/`:

- `<Feature>Destination.swift` — push targets + a `RoutableDestinationViewModifier`
- `<Feature>Sheet.swift` — modal targets + a `RoutableSheetViewModifier`
- `<Feature>Error.swift` — error targets + a `RoutableErrorViewModifier` (may also
  carry unrelated `VisualError`/`Equatable` conformances bolted on — keep those,
  they're not part of the navigation system, just colocated)
- `<Feature>Router.swift` — the `Routable`-conforming class

**There is no single fixed file this collapses into.** Looking at the two
completed migrations (TorrentList, Settings), the model ends up nested as an
`extension` on whichever view or Flow actually owns that piece of navigation
state, named simply `Model` (or `<Feature>Model` when nested on a `Flow` that
also has other things called `Model`):

- `TorrentListView.Model`, nested in `TorrentListView.swift` — one model for
  the whole feature, because TorrentList only has one navigable level (list →
  detail).
- `TorrentSettingsFlow.TorrentSettingsModel`, `TorrentSettingsListView.Model`,
  `AddServerView.Model` — Settings needed **three separate, view-local
  models**, one per screen in a genuinely multi-level push stack (list →
  add-a-server → add-new-server). Each pushed view chains its own
  `.navigationDestination(item:)` off its own model rather than one router
  owning the whole stack. See "Multi-level stacks: chain per-view models, not
  a shared path" below.

Decide file placement per-feature: if a feature has one navigable level,
nest one `Model` in its root view (or Flow). If a feature genuinely has
multiple push levels, give **each pushed screen its own nested `Model`** with
its own `Destination` enum for whatever it pushes next — don't force a single
model to hold every level's destinations.

An `@Observable final class Model` contains:
   - `var destination: Destination?` for this view's push target(s)
   - `var error: Error?` for this view's error/modal presentation state, if
     this view is the one presenting errors (not every nested model needs
     one — e.g. `AddServerView.Model` above only has `destination`)
   - `@CasePathable` enums `Destination` and `Error`, nested inside the model
   - No `push`/`pop`/`presentError`/`dismissError` wrapper methods needed —
     call sites just assign the property directly (`model.destination = .foo`,
     `model.destination = nil`), since swift-navigation's per-case bindings
     make the wrapper methods redundant

Any unrelated conformances that lived in the old `<Feature>Error.swift` (e.g.
`VisualError`, `Equatable` on a client error type) move to wherever makes
sense now — they were never part of the navigation system, just colocated.

Do **not** carry over `<Feature>DestinationModifier` / `<Feature>SheetModifier`
/ `<Feature>ErrorModifier` `ViewModifier` structs or their `withX(...)` `View`
extensions. Those move directly onto the owning view's `body` (see below) — a
dedicated `ViewModifier` + `View` extension per concern is pure indirection
once Router's multi-file convention is gone.

### One enum per presentation surface, not per feature

TorrentList ended up with two enums on `TorrentListView.Model`: `Destination`
(just `.detail`, driving `.navigationDestination(item:)`) and `Error`
(`.clientError` / `.fileImportError`, driving `.panel(item:)`). They're
consumed by two different SwiftUI modifiers that each need an **exhaustive**
switch over only their own cases. A single merged enum forces dead
`fatalError`/default branches in one modifier or the other — avoid that. Keep
push targets and modal/error targets in separate `@CasePathable` enums, even
though both live on the same model — this is the split documented in the
swift-navigation skill (`.claude/skills/swift-navigation/SKILL.md`); read it
for the "why" (two things that can be on screen at once must not share one
optional).

`TorrentSettingsListView.Model` follows the same split with a twist: its
`Destination` enum is genuinely two-case-deep-capable but only needs one enum
because the feature's *next* push level (`AddServerView`) is a **separate
model on a separate view**, not a third case bolted onto the same enum — see
below.

### Multi-level stacks: chain per-view models, not a shared path

The swift-navigation skill describes two options for a stack: item-based
`.navigationDestination(item:)` for one push level, or array-based
`.navigationDestination(for:)` on `NavigationStack(path: [Destination])` for a
"genuine multi-level stack." **This codebase's Settings migration found a
third option that isn't in the skill: chain single-level, item-based models
across views.**

Concretely, Settings' list → add-a-server → add-new-server stack is *not* one
`NavigationStack(path:)` with a three-case enum. It's three views, each with
its own one-level `Model`:

```swift
// TorrentSettingsListView.Model.Destination
case editServer(TorrentServer)
case addAServer

// AddServerView.Model.Destination
case addNewServer(TorrentServerType)
```

`TorrentSettingsListView` pushes `AddServerView` via its own
`.navigationDestination(item: $model.destination)`; once on screen,
`AddServerView` has its *own* `model.destination` and its *own*
`.navigationDestination(item:)` for the next level. There's no shared path
array anywhere — the `NavigationStack` itself lives once at the `Flow` root
(`TorrentSettingsFlow`), but each screen along the way independently owns
"what does *this* screen push next."

Prefer this over the array/path form when the real shape is "each screen
pushes one fixed next screen" (a linear or tree-shaped flow) rather than "the
same screen type can recur at arbitrary, dynamic depth" (e.g. folder
browsing, recursive comment threads) — the array/path form is for the latter
case, which doesn't currently exist in this codebase.

## Wiring it into the Flow

**Neither completed migration puts its own `NavigationStack` inside the
`<Feature>Flow`.** Both rely on a `NavigationStack` that already exists higher
up (currently still `AppRouter`'s Router-based one, since the app root hasn't
migrated yet — see "Remaining Router-based features" above). Don't add a
`NavigationStack(path:)` to a Flow unless the feature genuinely needs to own
its own stack root; follow what's already there.

There are two real shapes, depending on how many navigable levels the feature
has:

**One level (TorrentList):** the model lives on the feature's root view, and
`.navigationDestination(item:)` / `.panel(item:)` are applied directly to it
inside the Flow's `body` — see `TorrentsListFlow.swift` /
`TorrentListView.swift` for the full version:

```swift
public struct <Feature>Flow: View {
    @State public var model: <Feature>RootView.Model = .init()
    // ... other dependencies (session, preferences, etc.) ...

    public var body: some View {
        @Bindable var model = model

        <Feature>RootView()
            .navigationDestination(item: $model.destination.detail) { $thing in
                DetailView(thing: thing)
                    .environment(model)
            }
            .panel(item: $model.error.clientError) { error in
                ErrorPanelCard(error: error, primaryButtonAction: { model.error = nil })
            }
            .environment(model)
            // ... other .environment(...) injections ...
    }
}
```

**Multiple levels (Settings):** the `Flow` holds its own top-level model (for
whatever *it* directly presents), and each pushed screen along the way
chains its own model and its own `.navigationDestination(item:)` — see
"Multi-level stacks: chain per-view models, not a shared path" above and
`TorrentSettingsFlow.swift` / `TorrentSettingsListView.swift` /
`AddServerView.swift` for the full three-screen chain.

Notes:
- `@Bindable var model = model` shadows the `@State` property so `$model` works
  inside `body` — this is the same pattern already used elsewhere in the
  codebase for `@Bindable` locals (e.g. `TorrentListView.swift`), so it's
  consistent with existing style, not swift-navigation-specific.
- Use `$model.destination.someCase` (dynamic member lookup via
  `@CasePathable`) to get a `Binding<Payload?>` scoped to one case, not
  `$model.destination` directly, when the modifier should only react to that
  one case (see the `TorrentListView` example above, `.detail` /
  `.clientError`). Bind to the enum itself only when the modifier's switch is
  meant to be exhaustive over every case (see `TorrentSettingsListView`'s
  single `.navigationDestination(item: $model.destination)` with an internal
  `switch`).
- If the feature doesn't use the `.panel(item:)` custom presentation (see
  `documentation/error_handling.md`) and instead needs a plain `.sheet(item:)`
  for its `Destination`/`Sheet` enum, the same pattern applies — one
  `.sheet(item: $model.destination)` (or a scoped case binding) directly on
  the owning view, no separate modifier file.
- Every view inside the feature that used `@Environment(<Feature>Router.self)`
  becomes `@Environment(<Feature>Model.self)` (or whatever the local model's
  actual type is — see "no fixed file name" above). Call sites
  (`router.push(...)`, `router.presentError(...)`, `router.pop()`) become
  direct property assignment on the model (`model.destination = .foo`,
  `model.error = .bar`, `model.destination = nil` to pop/dismiss) — there are
  no wrapper methods to preserve call-site signatures for; update each call
  site to the new shape.

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
