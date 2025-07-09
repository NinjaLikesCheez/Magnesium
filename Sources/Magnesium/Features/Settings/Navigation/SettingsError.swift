import Router
import SwiftUI

enum SettingsError: RoutableError {
	var id: Self { fatalError("Not yet implemented") }
}

struct SettingsErrorModifier: RoutableErrorViewModifier {
	func body(content: Content) -> some View {
		content
	}
}

extension View {
	func withSettingsErrors() -> some View {
		modifier(SettingsErrorModifier())
	}
}
