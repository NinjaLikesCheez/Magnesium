import CommonUI
import SwiftUI
import SwiftUINavigation

struct TorrentDetailView: View {
	@State private var model = Model()

	var torrent: StandardTorrent

	var body: some View {
		@Bindable var model = model

		List {
			Section {
				HeaderView(torrent: torrent)
			}

			TorrentInformationSection(torrent: torrent)

			TorrentTrackerSection(torrent: torrent)

			TorrentFilesSection(torrent: torrent)
		}
		.buttonStyle(BorderlessButtonStyle())
		.navigationTitle("Info")
		.navigationBarTitleDisplayMode(.inline)
		.panel(item: $model.error.clientError) { error in
			ErrorPanelCard(
				error: error,
				primaryButtonAction: { model.error = nil }
			)
		}
		.environment(model)
	}
}

extension TorrentDetailView {
	/// Navigation + presentation state for the TorrentDetail screen.
	@Observable
	public final class Model {
		public var destination: Destination?
		public var error: Error?

		public init() {}

		/// Stack-navigation targets for the TorrentDetail screen. Currently a leaf with nothing to
		/// push, but kept alongside `Error` for consistency with `TorrentListModel`'s shape.
		@CasePathable
		public enum Destination: Hashable {}

		/// Modal error presentations for the TorrentDetail screen.
		@CasePathable
		public enum Error: Hashable {
			case clientError(TorrentClientError)
		}
	}
}
