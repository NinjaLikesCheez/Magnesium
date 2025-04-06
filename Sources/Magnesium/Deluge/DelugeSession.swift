import Deluge

typealias DelugeTorrentItem = TorrentItem

struct DelugeSession {
	let client: Deluge
	let torrents = [StandardTorrent]()
	let labels = [StandardLabel]()

	func refresh() async throws -> ([StandardTorrent], [StandardLabel]) {
		let torrentsAndLabels = try await client.request(.updateUIForApp)
		let torrents = torrentsAndLabels.torrents.compactMap(StandardTorrent.init)
		let labels = torrentsAndLabels.labels.map(StandardLabel.init)

		print("labels: \(labels), torrents: \(torrentsAndLabels.labels)")

		return (torrents, labels)
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
