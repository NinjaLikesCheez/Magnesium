import Deluge

public extension StandardTorrent {
	private static func state(for state: Torrent.State) -> StandardTorrentState {
		switch state {
		case .downloading:
			return .downloading
		case .seeding:
			return .seeding
		case .paused:
			return .paused
		case .checking:
			return .checking
		case .queued:
			return .queued
		case .error:
			return .error
		}
	}

	convenience init?(_ torrent: Torrent) {
		guard let dateAdded = torrent.dateAdded,
			let downloaded = torrent.downloaded,
			let downloadPath = torrent.downloadPath,
			let downloadRate = torrent.downloadRate,
			let eta = torrent.eta,
			let label = torrent.label,
			let peers = torrent.peers,
			let progress = torrent.progress,
			let seeds = torrent.seeds,
			let seedingTime = torrent.seedingTime,
			let size = torrent.size,
			let state = torrent.state.map(Self.state),
			let totalPeers = torrent.totalPeers,
			let totalSeeds = torrent.totalSeeds,
			let trackers = torrent.trackers?.map(\.url),
			let uploaded = torrent.uploaded,
			let uploadRate = torrent.uploadRate,
			let name = torrent.name
		else {
			return nil
		}

		self.init(
			dateAdded: dateAdded,
			downloaded: downloaded,
			downloadPath: downloadPath,
			downloadRate: downloadRate,
			eta: eta,
			hash: torrent.hash,
			label: label,
			name: name,
			peers: peers,
			progress: progress,
			seeds: seeds,
			seedingTime: seedingTime,
			size: size,
			state: state,
			totalPeers: totalPeers,
			totalSeeds: totalSeeds,
			trackers: trackers,
			uploaded: uploaded,
			uploadRate: uploadRate
		)
	}
}
