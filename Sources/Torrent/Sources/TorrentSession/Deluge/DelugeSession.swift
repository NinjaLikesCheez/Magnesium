import Deluge

typealias DelugeTorrentFile = TorrentFile
typealias DelugeTorrentItem = TorrentItem

struct DelugeSession {
	let client: Deluge
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
	var standard: StandardTorrentPriority {
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
	static var updateUIForApp: DelugeRequest<TorrentsAndLabels> {
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
