import Router
import CommonUI
import SwiftUI

public enum TorrentOnboardingError: RoutableError {
	public var id: Self { self }

	case addServerError(ServerSettingsError)
}

struct TorrentOnboardingErrorModifier: RoutableErrorViewModifier {
	@Binding var router: TorrentOnboardingRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .addServerError(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
					)
				}
			}
	}
}

extension View {
	func withTorrentOnboardingErrors(router: Binding<TorrentOnboardingRouter>) -> some View {
		modifier(TorrentOnboardingErrorModifier(router: router))
	}
}
