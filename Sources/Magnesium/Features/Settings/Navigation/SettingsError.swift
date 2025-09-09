import Router
import SwiftUI

enum SettingsError: RoutableError {
	var id: Self { self }

	case preferences(AppPreferences.Error)
	case serverSettings(ServerSettingsError)
	case session(Session.Error)
}

struct SettingsErrorModifier: RoutableErrorViewModifier {
	@Binding var router: SettingsRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .preferences(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
					)
				case let .serverSettings(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
					)
				case let .session(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
					)
				}
			}
	}
}

extension View {
	func withSettingsErrors(router: Binding<SettingsRouter>) -> some View {
		modifier(SettingsErrorModifier(router: router))
	}
}
