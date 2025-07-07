# Navigation

## Overview

The app uses a router-based navigation system (inspired by [Ice Cubes App](https://github.com/Dimillian/IceCubesApp) with some tweaks) built on top of SwiftUI's `NavigationStack`. This system provides a clean, testable, and maintainable way to handle navigation throughout the app.

The architecture consists of:

- **Router Protocol**: Defines the navigation interface
- **Destinations**: Enum cases representing push navigation targets
- **Sheets**: Enum cases representing modal presentations
- **View Modifiers**: Extensions that handle navigation destination and sheet presentation

## Architecture

### Router Protocol (`Router.swift`)

The `RouterProtocol` is the core of the navigation system. It defines the interface for all navigation routers:

```swift
@MainActor
protocol RouterProtocol: AnyObject, Observation.Observable {
	associatedtype Destination: RoutableDestination
	associatedtype Sheet: RoutableSheet

	var path: [Destination] { get set }
	var presentedSheet: Sheet? { get set }
	var parent: (any RouterProtocol)? { get }

	init(_ parent: (any RouterProtocol)?)

	func push(_ destination: Destination)
	@discardableResult func pop() -> Destination?
	func popToRoot()
	func presentSheet(_ sheet: Sheet)
	func dismissSheet(withParent: Bool)
	func reset(withParent: Bool)
}
```

### Key Components

1. **Destinations**: Conform to `RoutableDestination` protocol, used for stack navigation
2. **Sheets**: Conform to `RoutableSheet` protocol, used for modal presentations
3. **Parent Router**: Enables hierarchical navigation where child routers can affect parent navigation

### Default Implementation

The protocol provides default implementations for all navigation methods:

- `push(_:)`: Adds a destination to the navigation path
- `pop()`: Removes the last destination from the path
- `popToRoot()`: Clears the entire navigation path
- `presentSheet(_:)`: Sets the presented sheet
- `dismissSheet(withParent:)`: Dismisses the sheet, optionally affecting parent router
- `reset(withParent:)`: Resets both path and sheet, optionally affecting parent router

## Creating a New Router

### Step 1: Define Destinations

Create an enum conforming to `RoutableDestination`:

```swift
enum YourFeatureDestinations: RoutableDestination {
	var id: Self { self }

	case detailView(SomeModel)
	case settingsView
	case listView(parameters: SomeParameters)
}
```

### Step 2: Define Sheets

Create an enum conforming to `RoutableSheet`:

```swift
enum YourFeatureSheets: RoutableSheet {
	var id: Self { self }

	case addItemSheet
	case editItemSheet(SomeModel)
	case confirmationSheet(message: String)
}
```

### Step 3: Create the Router

Implement the `RouterProtocol`:

```swift
import Observation

@Observable
final class YourFeatureRouter: RouterProtocol {
	typealias Destination = YourFeatureDestinations
	typealias Sheet = YourFeatureSheets

	var path: [YourFeatureDestinations] = []
	var presentedSheet: YourFeatureSheets? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
```

### Step 4: Create Destination Modifier

Create a view modifier to handle navigation destinations:

```swift
struct YourFeatureDestinationsModifier: ViewModifier {
	func body(content: Content) -> some View {
		content
			.navigationDestination(for: YourFeatureDestinations.self) { destination in
				switch destination {
				case .detailView(let model):
					DetailView(model: model)
				case .settingsView:
					SettingsView()
				case .listView(let parameters):
					ListView(parameters: parameters)
				}
			}
	}
}

extension View {
	func withYourFeatureDestinations() -> some View {
		modifier(YourFeatureDestinationsModifier())
	}
}
```

### Step 5: Create Sheet Modifier

Create a view modifier to handle sheet presentations:

```swift
struct YourFeatureSheetsModifier: ViewModifier {
	@Binding var router: YourFeatureRouter

	func body(content: Content) -> some View {
		content
			.sheet(item: $router.presentedSheet) { sheet in
				switch sheet {
				case .addItemSheet:
					AddItemView()
				case .editItemSheet(let model):
						EditItemView(model: model)
				case .confirmationSheet(let message):
					ConfirmationView(message: message)
				}
			}
	}
}

extension View {
	func withYourFeatureSheets(router: Binding<YourFeatureRouter>) -> some View {
			modifier(YourFeatureSheetsModifier(router: router))
	}
}
```

### Step 6: Create the Flow View

Create a flow view that sets up the navigation:

```swift
struct YourFeatureFlow: View {
	@State var router: YourFeatureRouter

	var body: some View {
		NavigationStack(path: $router.path) {
			YourFeatureRootView()
				.withYourFeatureDestinations()
				.withYourFeatureSheets(router: $router)
		}
		.environment(router)
	}
}
```

## Using Routers in Views

### Accessing the Router

In any view within the navigation hierarchy, access the router via environment:

```swift
struct SomeView: View {
	@Environment(YourFeatureRouter.self) private var router

	var body: some View {
			// View content
	}
}
```

### Navigation Actions

#### Push Navigation

```swift
// Navigate to a detail view
router.push(.detailView(someModel))

// Navigate to settings
router.push(.settingsView)
```

#### Modal Presentation

```swift
// Present a sheet
router.presentSheet(.addItemSheet)

// Present sheet with data
router.presentSheet(.editItemSheet(someModel))
```

#### Going Back

```swift
// Pop one level
router.pop()

// Pop to root
router.popToRoot()

// Dismiss sheet
router.dismissSheet()

// Dismiss sheet and affect parent router
router.dismissSheet(withParent: true)
```

#### Reset Navigation

```swift
// Reset current router
router.reset()

// Reset current router and parent
router.reset(withParent: true)
```

## Best Practices

### 1. Router Naming

- Router: `{Feature}Router` (e.g., `SettingsRouter`)
- Destinations: `{Feature}Destinations` (e.g., `SettingsDestinations`)
- Sheets: `{Feature}Sheets` (e.g., `SettingsSheets`)

### 2. Environment Setup

Always provide the router via environment in your flow view:

```swift
NavigationStack(path: $router.path) {
	RootView()
}
.environment(router)
```

### 3. Hierarchical Navigation

When creating child routers, pass the parent router:

```swift
let childRouter = ChildRouter(parentRouter)
```

### 4. Generic Views

When creating views that work with multiple router types, use generics:

```swift
struct AddServerView<Router: RouterProtocol>: View {
	@Environment(Router.self) private var router

	var body: some View {
		// Implementation
	}
}
```

## Testing

The router system is designed to be testable:

```swift
func testNavigation() {
	let router = YourFeatureRouter()

	// Test push navigation
	router.push(.detailView(testModel))
	XCTAssertEqual(router.path.count, 1)

	// Test sheet presentation
	router.presentSheet(.addItemSheet)
	XCTAssertNotNil(router.presentedSheet)

	// Test pop
	router.pop()
	XCTAssertEqual(router.path.count, 0)
}
```
