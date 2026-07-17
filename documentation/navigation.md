# Navigation

## Overview

The app uses [pointfreeco/swift-navigation](https://github.com/pointfreeco/swift-navigation) (`SwiftNavigation`/`SwiftUINavigation`) for navigation: a `@CasePathable` enum describes everywhere a screen can go, and each case gets its own `Binding<Payload?>` via dynamic member lookup (`$model.destination.detail`). That binding drives a native SwiftUI presentation primitive — `.navigationDestination(item:)`, `.sheet(item:)`, `.panel(item:)` (this app's error/modal card, see [error_handling.md](error_handling.md)) — so each presentation site gets an exhaustive switch over only its own cases.

The app previously used a custom `Router` package for navigation; that migration is now complete and the `Router` dependency has been removed entirely. **This document describes the pattern used for all navigation code.**

For general swift-navigation anti-patterns (the two-enum split, `Identifiable` payloads, why not to hand-roll modal overlays, item- vs. array-based navigation), read the **swift-navigation** skill (`.claude/skills/swift-navigation/SKILL.md`) — it covers the library in general; this document covers how the library is actually used in this codebase.

## Architecture

### The model

Each view that owns navigation state defines its own `@Observable final class Model`, nested as an `extension` on the owning view or `Flow`. **There is no single shared `<Feature>Model.swift` file or naming convention** — the model lives wherever the view that presents things actually is:

```swift
// TorrentListView.swift
extension TorrentListView {
	@Observable
	public final class Model {
		public var error: Error?
		public var destination: Destination?

		@CasePathable
		public enum Destination: Hashable {
			case detail(StandardTorrent)
		}

		@CasePathable
		public enum Error: Hashable {
			case clientError(TorrentClientError)
			case fileImportError(FileImportError)
		}
	}
}
```

Real examples in the codebase:
- `TorrentListView.Model` — nested in [`TorrentListView.swift`](../Packages/Torrent/Sources/TorrentUI/TorrentList/TorrentListView.swift). One model for the whole feature, since TorrentList only has one navigable level (list → detail).
- `TorrentSettingsFlow.TorrentSettingsModel`, `TorrentSettingsListView.Model`, `AddServerView.Model` — three separate, view-local models, one per screen in a multi-level push stack (list → add-a-server → add-new-server). See "Multi-level stacks" below.

There are no `push`/`pop`/`presentError`/`dismissError` wrapper methods — call sites assign the property directly:

```swift
model.destination = .detail(torrent)   // push
model.destination = nil                // pop
model.error = .clientError(error)      // present error
model.error = nil                      // dismiss error
```

### One enum per presentation surface, not per feature

Every model splits presentation state **by surface, not by feature**: a `destination` property for push targets (`.navigationDestination(item:)`), and a separate `error` property for modal/error state (`.panel(item:)` or `.sheet(item:)`) — never one enum covering both. This is the two-enum split from the swift-navigation skill: it keeps each modifier's switch exhaustive over only its own cases, and it means presenting an error can't silently pop whatever's currently pushed, since the two are independent optionals.

`Error` enum cases get `Identifiable` via `var id: Self { self }` on the enum itself (the cases are already `Hashable`), not a wrapper type:

```swift
@CasePathable
enum Error: Hashable, Identifiable {
	case preferences(TorrentPreferences.Error)

	var id: Self { self }
}
```

### Multi-level stacks: chain per-view models, not a shared path

For a screen that only pushes one level deep, one model with `.navigationDestination(item:)` is enough (see TorrentList above). For a genuinely multi-level stack, **chain a separate one-level model per screen** rather than a single array-based `NavigationPath`/`[Destination]`:

```swift
// TorrentSettingsListView.Model.Destination
case editServer(TorrentServer)
case addAServer

// AddServerView.Model.Destination
case addNewServer(TorrentServerType)
```

`TorrentSettingsListView` pushes `AddServerView` via its own `.navigationDestination(item: $model.destination)`; once on screen, `AddServerView` has its *own* `model.destination` and its *own* `.navigationDestination(item:)` for the next level. There's no shared path array — the `NavigationStack` itself lives once, at the root the `Flow` composes into, but each screen along the way independently owns "what does *this* screen push next."

Reach for this over an array-based `NavigationStack(path:)` + `.navigationDestination(for:)` whenever the real shape is "each screen pushes one fixed next screen" (a linear or tree-shaped flow). Save the array/path form for when the same screen type can recur at arbitrary, dynamic depth (e.g. folder browsing, recursive comment threads) — that case doesn't currently exist in this codebase.

## Wiring it into the Flow

Neither `TorrentsListFlow` nor `TorrentSettingsFlow` puts its own `NavigationStack` inside the Flow — both compose into a `NavigationStack` that already exists higher up the view hierarchy. Don't add a `NavigationStack(path:)` to a Flow unless the feature genuinely needs to own its own stack root.

**One level** — model on the root view, modifiers applied directly to it in the Flow's `body` (see [`TorrentsListFlow.swift`](../Packages/Torrent/Sources/TorrentUI/TorrentList/TorrentsListFlow.swift)):

```swift
public struct TorrentsListFlow: View {
	@State public var model: TorrentListView.Model = .init()
	let session: TorrentSession
	let preferences: TorrentPreferences
	let manager: TorrentManager

	public var body: some View {
		@Bindable var model = model

		TorrentNavigationView()
			.navigationDestination(item: $model.destination.detail) { $torrent in
				TorrentDetailView(torrent: torrent)
					.environment(manager)
			}
			.panel(item: $model.error.clientError) { error in
				ErrorPanelCard(error: error, primaryButtonAction: { model.error = nil })
			}
			.panel(item: $model.error.fileImportError) { error in
				PanelCard(
					title: "File Import Error",
					systemName: "square.and.arrow.down.badge.xmark",
					subtitle: error.message,
					primaryButtonAction: { model.error = nil }
				)
			}
			.environment(manager)
			.environment(model)
			.environment(preferences)
			.environment(session)
	}
}
```

**Multiple levels** — the `Flow` holds its own top-level model for whatever it directly presents, and each pushed screen chains its own model (see [`TorrentSettingsFlow.swift`](../Packages/Torrent/Sources/TorrentUI/Settings/TorrentSettingsFlow.swift), [`TorrentSettingsListView.swift`](../Packages/Torrent/Sources/TorrentUI/Settings/TorrentSettingsListView.swift), [`AddServerView.swift`](../Packages/Torrent/Sources/TorrentUI/Settings/AddServerView.swift) for the full three-screen chain).

Notes:
- `@Bindable var model = model` shadows the `@State` property so `$model` works inside `body` — existing codebase style for `@Bindable` locals, not swift-navigation-specific.
- Use `$model.destination.someCase` (dynamic member lookup via `@CasePathable`) to get a `Binding<Payload?>` scoped to one case when the modifier should only react to that case (see `.detail` / `.clientError` above). Bind to the enum itself, `$model.destination`, only when the modifier's own switch is meant to be exhaustive over every case (see `TorrentSettingsListView`'s single `.navigationDestination(item: $model.destination)` with an internal `switch`).
- Every view inside the feature accesses its model via `@Environment(SomeModel.self)` — there's no `RouterProtocol`-style abstraction; the environment key is just the concrete model type.

## Package dependencies

Depend on `swift-navigation` in the target's `Package.swift`:

```swift
.package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.4.1"),
```

```swift
.product(name: "SwiftNavigation", package: "swift-navigation"),
.product(name: "SwiftUINavigation", package: "swift-navigation"),
```

New macro dependencies (`SwiftNavigationMacros`, `CasePathsMacros`, and transitively `PerceptionMacros`) require a one-time interactive "Trust & Enable" approval in Xcode.app the first time they're built in a given DerivedData — this can't be done from the CLI. If a build fails with `Macro "..." must be enabled before it can be used`, open the project in Xcode and approve it there.

## Testing

Test the model directly — no router protocol or mocking required:

```swift
@Test
func testNavigation() {
	let model = TorrentListView.Model()

	model.destination = .detail(testTorrent)
	#expect(model.destination == .detail(testTorrent))

	model.destination = nil
	#expect(model.destination == nil)

	model.error = .clientError(testError)
	#expect(model.error != nil)
}
```
