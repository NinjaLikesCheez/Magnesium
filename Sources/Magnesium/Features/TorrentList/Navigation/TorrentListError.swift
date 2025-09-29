import Router
import SwiftUI
import Torrent

enum TorrentListError: RoutableError {
	var id: Self { self }

	case clientError(TorrentClientError)
	case fileImportError(String) // fileImport API throws any Error... so manually build it
}

struct TorrentListErrorModifier: RoutableErrorViewModifier {
	@Binding var router: TorrentListRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .clientError(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
					)
				case let .fileImportError(message):
					PanelCard(
						title: "File Import Error",
						systemName: "square.and.arrow.down.badge.xmark",
						subtitle: message,
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
