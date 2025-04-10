import SwiftUI

struct TorrentInformationItem: Identifiable {
	var id: String { label }

	var label: String
	var value: String
}

struct TorrentInformationSection: View {
	let items: [TorrentInformationItem]

	init(torrent: StandardTorrent) {
		items = [
			.init(label: "Size", value: Formatters.bytes.string(fromByteCount: torrent.size)),
			.init(label: "Download Speed", value: Formatters.bytes.string(fromByteCount: torrent.downloadRate)),
			.init(label: "Upload Speed", value: Formatters.bytes.string(fromByteCount: torrent.uploadRate)),
			.init(label: "Downloaded", value: Formatters.bytes.string(fromByteCount: torrent.downloaded)),
			.init(label: "Uploaded", value: Formatters.bytes.string(fromByteCount: torrent.uploaded)),
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
