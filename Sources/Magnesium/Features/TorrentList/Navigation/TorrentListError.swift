import Router
import SwiftUI

enum TorrentListError: RoutableError {
	var id: Self { self }

	case clientError(TorrentClientError)
}

struct TorrentListErrorModifier: RoutableErrorViewModifier {
	@Binding var router: TorrentListRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .clientError(error):
					PanelCard(
						title: error.title,
						systemName: error.systemName,
						subtitle: error.subtitle,
						primaryButtonAction: router.dismissError
					)
				}
			}
	}
}

extension View {
	func withTorrentListErrors(router: Binding<TorrentListRouter>) -> some View {
		modifier(TorrentListErrorModifier(router: router))
	}
}
