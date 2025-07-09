import Router
import SwiftUI

enum TorrentListError: RoutableError {
	var id: Self { fatalError("Not yet implemented") }
}

struct TorrentListErrorModifier: RoutableErrorViewModifier {
	func body(content: Content) -> some View {
		content
	}
}

extension View {
	func withTorrentListErrors() -> some View {
		modifier(TorrentListErrorModifier())
	}
}
