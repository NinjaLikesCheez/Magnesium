import SwiftUI
import Torrent

struct TorrentDetailView: View {
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
