# Error Handling

Errors should be propagated by typed throwing functions where possible. When an error will be surfaced to the user, conform to the [`VisualError`](../Sources/Magnesium/Common/VisualErrors.swift) protocol.

For example, given an error and conformance:

```swift
enum NetworkError: Swift.Error {
	case noNetworkAccess
}

extension NetworkError: VisualError {
	var title: String {
		switch self {
		case .noNetworkAccess:
			"Unable to Connect"
		}
	}

	var systemName: String {
		switch self {
		case .noNetworkAccess:
			"network.slash"
		}
	}

	var subtitle: String {
		switch self {
		case .noNetworkAccess:
			"It looks like you're offline, please reconnect and try again"
		}
	}
}
```

This is then used as a case's payload in a feature's `Error` enum (see [navigation.md](./navigation.md) for the full navigation model). The `Error` enum lives nested on the feature's own `Model`, is `Identifiable` via `var id: Self { self }`, and is presented with `.panel(item:)`:

```swift
extension SomeFeatureView {
	@Observable
	final class Model {
		var error: Error?

		@CasePathable
		enum Error: Hashable, Identifiable {
			case network(NetworkError)

			var id: Self { self }
		}
	}
}

struct SomeFeatureFlow: View {
	@State var model: SomeFeatureView.Model = .init()

	var body: some View {
		@Bindable var model = model

		SomeFeatureView()
			.panel(item: $model.error.network) { error in
				ErrorPanelCard(
					error: error,
					primaryButtonAction: { model.error = nil }
				)
			}
			.environment(model)
	}
}
```

Always route user-facing errors through `ErrorPanelCard`/`panel(item:)` this way rather than presenting an ad hoc alert — it's what keeps `VisualError` conformance meaningful across the whole app.
