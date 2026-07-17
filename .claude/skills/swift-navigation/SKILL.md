---
name: swift-navigation
description: Best practices and anti-patterns for pointfreeco/swift-navigation (and SwiftUINavigation) in SwiftUI apps — @CasePathable destination enums, per-case navigationDestination(item:)/sheet(item:)/panel bindings, and avoiding state-modeling and presentation-layering bugs. Trigger whenever the user is adding push/sheet/alert/fullScreenCover navigation driven by an enum, migrating a screen off a custom router onto swift-navigation, designing a screen's navigation/error model, or debugging a presentation that's misbehaving (wrong content showing, dismiss not animating, content appearing behind toolbar/tab bar chrome, dead switch branches in a navigationDestination). Also use this when the user asks "should this be one enum or two" for a screen's destinations, or reports a modal/panel visually cut off or bleeding through system chrome.
---

# swift-navigation

[swift-navigation](https://github.com/pointfreeco/swift-navigation) (and its SwiftUI-specific companion, `SwiftUINavigation`) gives SwiftUI enum-driven navigation: a single `@CasePathable` enum describes every place a screen can go, and each case gets its own `Binding<Payload?>` derived automatically via dynamic member lookup (`$model.destination.detail`). That binding then drives whichever native SwiftUI presentation primitive fits — `navigationDestination(item:)`, `sheet(item:)`, `fullScreenCover(item:)`, `popover(item:)`, `alert(item:)` — each getting an *exhaustive*, narrowed view of just its own case.

The value of this library is almost entirely in that per-case binding mechanism. Read this skill before writing the enum, not after — the mistakes below are all things that compile fine, run fine in the simple case, and only surface once a screen has two independent things that can be on screen at once, or once a modal collides with system chrome.

## Setting up the model

```swift
import SwiftUINavigation

@Observable
final class ScreenModel {
	var path: Destination?

	@CasePathable
	enum Destination: Hashable {
		case detail(Item)
		case addItem
		case confirmDelete(Item)
	}
}
```

`@CasePathable` (from `swift-case-paths`, re-exported by `SwiftUINavigation`) generates the dynamic-member bindings. You get `$model.path.detail`, `$model.path.addItem`, etc. — each a `Binding<CaseValue?>` that reads/writes through to the shared `path` property, automatically nil-ing out other cases when set.

Wire it up:

```swift
SomeRootView()
	.navigationDestination(item: $model.path.detail) { $item in
		DetailView(item: item)
	}
	.sheet(item: $model.path.addItem) { _ in
		AddItemView()
	}
	.confirmationDialog(item: $model.path.confirmDelete) { item in
		Button("Delete \(item.name)", role: .destructive) { ... }
	}
```

Each modifier only ever sees its own case — no `switch` needed at the call site when there's exactly one payload per presentation, and when there is a switch (e.g. one `.sheet` serving multiple related cases) it only has to cover the cases that are actually possible there.

## Anti-pattern: one enum holding everything, forcing dead branches

It's tempting to read the library's examples and conclude "one `Destination` enum should hold every possible thing this screen can do," including cases that are never valid together. This breaks down as soon as a `switch` needs to be **exhaustive** over cases that don't belong in that context.

Concretely: if `Destination` has `.detail(Item)` (a push target) and `.loadError(Error)` (an error panel), and you try to drive both from `.navigationDestination(for: Destination.self)` (the array-based, not item-based, form), that switch must handle `.loadError` too — even though an error should never be pushed onto the stack. You end up writing `default: fatalError(...)` or a silent empty view, which is a landmine: it compiles, looks harmless, and crashes or silently misbehaves the one time application logic manages to route the "wrong" case there.

**The fix is not to abandon the shared enum — it's to give each independent presentation surface its own optional property**, even if the case *types* live together:

```swift
@Observable
final class ScreenModel {
	var path: Path?          // push destinations only
	var alert: AlertState?   // errors/confirmations only

	@CasePathable
	enum Path: Hashable { case detail(Item) }

	@CasePathable
	enum AlertState: Hashable { case loadError(LoadError), confirmDelete(Item) }
}
```

Now `.navigationDestination(item: $model.path.detail)` is trivially exhaustive (one case, no switch), and the alert surface's switch never has to think about push targets. This is the shape used in the library's own `Inventory` example app and in the "enum navigation" case study — one enum *per presentation surface*, not one enum for the whole screen.

### The sharper trap: two things that can be on screen at once

The single-shared-optional problem gets worse, not better, when two presentations can be **simultaneously visible**. A very common real case: a detail screen is pushed, and while it's still on screen the user triggers an action that fails and needs to show an error — without popping the detail view. If push and error share one `Destination?` property, presenting the error silently dismisses whatever was pushed, because setting `path = .error(...)` overwrites `path = .detail(...)`. There is no visual glitch to warn you — the detail view just vanishes at the exact moment the error appears, and it's easy to misdiagnose as an animation bug rather than a state-modeling one.

Rule of thumb: **before merging two cases into one optional, ask "can both of these be true on screen at the same time?"** If yes, they need independent `@State`/`@Observable` properties (each can still be its own `@CasePathable` enum), never a shared one, no matter how tempting it is to have "just one `Destination` for this screen."

## Choosing item-based vs. array-based navigation

- `.navigationDestination(item: Binding<Item?>)` — use when a screen only ever pushes **one level deep** from itself (list → detail, with nothing pushing further). This is the common case for a leaf feature screen, and it's what lets a single `Destination` enum stay exhaustive without dead branches, since there's no "path so far" to reason about.
- `.navigationDestination(for: SomeType.self)` on a `NavigationStack(path: [SomeType])` — use for a genuine multi-level stack where the same screen type can be pushed multiple times or the stack depth varies. Needed when you actually have a `[Destination]` array, not just an optional.

Don't reach for the array/path form by default "in case the screen grows more levels later." It's more machinery, and if it's not needed yet it just means more surface area for the dead-branch anti-pattern above. Add it when a second level actually exists.

## Anti-pattern: forgetting `Identifiable` on payloads

Every item-based presentation modifier (`navigationDestination(item:)`, `sheet(item:)`, `fullScreenCover(item:)`, `popover(item:)`) requires the case's payload to be `Identifiable` (exactly like vanilla SwiftUI's `.sheet(item:)` does — this isn't swift-navigation-specific, but it bites more often here because it's easy to add a case with a `String` or a plain struct payload without thinking about it).

If a payload is a bare `String` (e.g. an error message with no natural identity), don't reach for a blanket `extension String: Identifiable` — that's a global conformance on a foundational type that silently affects every other `String` usage in the module, which can mask unrelated bugs (accidental identity-based diffing on unrelated strings, for instance). Wrap it instead:

```swift
struct ImportError: Hashable, Identifiable {
	var id: String { message }
	let message: String
}
```

Small, scoped to the one case that needs it, and the `id` is still cheap to derive from the content itself when there's no better identity available.

## Anti-pattern: presenting error/modal content with a hand-rolled overlay instead of a native presentation modifier

If a screen has a `.toolbar` with `.bottomBar`-placed items (or any system chrome — tab bars, navigation bars), **do not build a custom "panel" or modal as an in-place `ZStack` overlay** applied via a regular `ViewModifier`. `.toolbar` content is composited by UIKit/AppKit in a layer that sits above ordinary SwiftUI view content regardless of `ZStack` order in the view tree — no amount of reordering modifiers, `.zIndex()`, or `.ignoresSafeArea()` on the overlay will make it draw on top of toolbar chrome, because the toolbar isn't part of the same compositing layer at all.

Symptoms this produces, which are easy to misdiagnose as something else:
- Toolbar buttons/icons visibly "bleed through" a modal that's supposedly covering the whole screen.
- Taps meant for the modal land on a toolbar button instead, because the toolbar is also above the modal in hit-testing.
- The bug reproduces identically no matter where in the view hierarchy the overlay modifier is applied, including inside a freshly nested `NavigationStack` — because the toolbar is still a sibling/ancestor UIKit layer, not a SwiftUI z-order problem.

**The fix**: drive the presentation through a native SwiftUI presentation primitive — `.sheet(item:)`, `.fullScreenCover(item:)`, `.popover(item:)`, `.alert(item:)` — which SwiftUI/UIKit guarantee to composite above all chrome, the same layer system alerts and sheets already use. If you want a custom look (e.g. a bottom-anchored card with a dimmed backdrop, not the system's opaque cover), use `.fullScreenCover(item:)` with `.presentationBackground(.clear)` and build the dimmed-backdrop-plus-card look *inside* the cover's content — you keep full visual control while getting the correct compositing layer for free.

When retrofitting a custom overlay component this way, watch for one subtlety: `.fullScreenCover(item:)`'s binding *is* the presentation trigger, so if external code sets the bound `Item?` to `nil` to dismiss (e.g. a "Done" button calling `model.error = nil`), the cover disappears immediately with no chance to play a close animation. If a slide-out/fade-out animation matters, don't bind the cover directly to the caller's item — keep an internal `@State private var presentedItem: Item?` that the cover is actually bound to, animate that to a "closed" visual state first, and only clear `presentedItem` (dismissing the cover) after the animation's duration elapses. The externally-owned binding stays the semantic source of truth; the internal proxy just delays the actual teardown long enough to be seen.

## Quick diagnostic checklist

When something in an enum-driven navigation setup misbehaves, check in this order:

1. **Wrong/missing content appears when it shouldn't, or a screen vanishes unexpectedly** → look for two presentation concerns sharing one optional property. Ask "can both be true at once?"
2. **A `switch` over the destination enum has a `default:`/`fatalError` branch** → that enum is doing too much; split it by presentation surface (see above).
3. **Payload type doesn't conform to `Identifiable` and the compiler complains at the `item:` call site** → wrap it in a small `Identifiable` struct rather than adding a blanket conformance to a shared type.
4. **A modal/panel is visually cut off, has content bleeding through it, or taps land on the wrong element** — and the screen has a `.toolbar` (especially `.bottomBar`) → the overlay is being drawn in the wrong compositing layer. Switch to a native item-based presentation modifier.
5. **A custom dismiss animation stopped playing after switching to `.sheet`/`.fullScreenCover`** → check whether the presentation binding is tied directly to externally-owned state; add an internal proxy state var if the close animation needs to run before the binding actually clears.
