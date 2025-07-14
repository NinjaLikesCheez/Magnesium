import Router
import SwiftUI

enum SettingsError: RoutableError {
	var id: Self { self }

	case preferences(AppPreferences.Error)
}

struct SettingsErrorModifier: RoutableErrorViewModifier {
	@Binding var router: SettingsRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .preferences(error):
					PanelCard(
						title: error.title, systemName: error.systemName, subtitle: error.subtitle,
						primaryButtonAction: router.dismissError)
				}
			}
	}
}

extension View {
	func withSettingsErrors(router: Binding<SettingsRouter>) -> some View {
		modifier(SettingsErrorModifier(router: router))
	}
}
