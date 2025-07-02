import Deluge

typealias DelugeTorrentFile = TorrentFile
typealias DelugeTorrentItem = TorrentItem

struct DelugeSession {
	let client: Deluge

	func refresh() async throws -> ([StandardTorrent], [StandardLabel]) {
		let torrentsAndLabels = try await client.request(.updateUIForApp)
		let torrents = torrentsAndLabels.torrents.compactMap(StandardTorrent.init)
		let labels = torrentsAndLabels.labels.map(StandardLabel.init)

		return (torrents, labels)
	}
}

extension DelugeTorrentFile {
	var standard: StandardTorrentFile {
		.init(
			index: index,
			name: name,
			size: size,
			progress: progress,
			priority: priority.standard
		)
	}
}

extension Priority {
	var standard: TorrentPriority {
		switch self {
		case .disabled:
			.disabled
		case .low:
			.low
		case .normal:
			.normal
		case .high:
			.high
		default:
			.normal
		}
	}
}

extension DelugeRequest {
	fileprivate static var updateUIForApp: DelugeRequest<TorrentsAndLabels> {
		let properties: [Torrent.PropertyKeys] = [
			.dateAdded,
			.downloaded,
			.downloadPath,
			.downloadRate,
			.eta,
			.label,
			.name,
			.peers,
			.progress,
			.seeds,
			.size,
			.state,
			.totalPeers,
			.totalSeeds,
			.trackers,
			.uploaded,
			.uploadRate,
		]

		return Self.updateUI(properties: properties)
	}
}
