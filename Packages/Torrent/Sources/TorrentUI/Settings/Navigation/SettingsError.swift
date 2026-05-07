import Router
import SwiftUI
import CommonUI

public enum TorrentSettingsError: RoutableError {
	public var id: Self { self }

	case preferences(TorrentPreferences.Error)
	case serverSettings(ServerSettingsError)
	case session(TorrentSession.Error)
}

struct TorrentSettingsErrorModifier: RoutableErrorViewModifier {
	@Binding var router: TorrentSettingsRouter

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
	func withSettingsErrors(router: Binding<TorrentSettingsRouter>) -> some View {
		modifier(TorrentSettingsErrorModifier(router: router))
	}
}
