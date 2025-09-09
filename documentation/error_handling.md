# Error Handling

Errors should be propagated by typed throwing functions where possible. When an error will be surfaced to the user, conform to the [`VisualError`](../Sources/Magnesium/Common/VisualErrors.swift) protocol.

For example, given an error and conformance:

```swift
enum NetworkError: Swift.Error {
	case noNetworkAccess
}

extension Error: VisualError {
	var title: String {
		switch self {
		case .noNetworkAccess:
			"Unable to Connect"
		}
	}

	var systemName: String {
		switch self {
		case .system, .unknown:
			"network.slash"
		}
	}

	var subtitle: String {
		switch self {
		case let .noNetworkAccess:
			"It looks like you're offline, please reconnect and try again"
		}
	}
}
```

This can then be used as the associated type of a `RoutableError` (which should be the base of all your possible UI errors - see [navigation.md](./navigation.md) for more):

```swift
enum SomeRoutableError: RoutableError {
	var id: Self { self }

	case network(NetworkError)
}

struct SomeRoutableErrorModifier: RoutableErrorViewModifier {
	@Binding var router: SomeRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .network(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError)
				}
			}
	}
}
```

The compiler should, in theory, enforce the type safety of the associated type provided you use the `ErrorPanelCard` for all presented errors (which you should).
