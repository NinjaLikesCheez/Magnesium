import SwiftUI
import SwiftUINavigation
import CommonUI

struct TorrentDetailView: View {
	@State private var model = TorrentDetailModel()

	var torrent: StandardTorrent

	var body: some View {
		@Bindable var model = model

		List {
			Section {
				TorrentDetailHeaderView(torrent: torrent)
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
