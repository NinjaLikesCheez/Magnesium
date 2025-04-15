import SwiftUI

struct TorrentDetailView: View {
	@Environment(TorrentActionImplementation.self) var implementation
	var torrent: StandardTorrent

	var body: some View {
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
	}
}
