import SwiftUI
import Common
import Torrent

struct TorrentInformationItem: Identifiable {
	var id: String { label }

	var label: String
	var value: String
}

struct TorrentInformationSection: View {
	let items: [TorrentInformationItem]

	init(torrent: StandardTorrent) {
		items = [
			.init(label: "Size", value: torrent.size.formatted(Formatters.bytes)),
			.init(label: "Download Speed", value: torrent.downloadRate.formatted(Formatters.bytes)),
			.init(label: "Upload Speed", value: torrent.uploadRate.formatted(Formatters.bytes)),
			.init(label: "Downloaded", value: torrent.downloaded.formatted(Formatters.bytes)),
			.init(label: "Uploaded", value: torrent.uploaded.formatted(Formatters.bytes)),
			.init(label: "ETA", value: torrent.formattedETA),
			.init(label: "Ratio", value: torrent.formattedRatio()),
			.init(label: "Peers", value: "\(torrent.peers)"),
			.init(label: "Seeds", value: "\(torrent.seeds)"),
			.init(label: "Download Folder", value: torrent.downloadPath)
		]
	}

	var body: some View {
		Section {
			ForEach(items) { item in
				HStack {
					Text(item.label)
						.foregroundStyle(.secondary)
					Spacer()
					Text(item.value)
				}
			}
		} header: {
			Text("Information")
				.font(.headline)
		}
	}
}
