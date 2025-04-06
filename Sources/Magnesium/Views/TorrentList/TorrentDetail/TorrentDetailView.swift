import SwiftUI

struct TorrentDetailView: View {
	@Environment(TorrentActionImplementation.self) var implementation
	var torrent: StandardTorrent

	var body: some View {
		List {
			Section {
				TorrentDetailHeaderView(torrent: torrent)
			}
			Section {
				TorrentInformationSection(torrent: torrent)
			} header: {
				Text("Information")
					.font(.headline)
			}
		}
		.buttonStyle(BorderlessButtonStyle())
	}
}
