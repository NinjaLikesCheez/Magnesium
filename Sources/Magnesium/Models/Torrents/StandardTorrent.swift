import Foundation
import Observation

@Observable
final class StandardTorrent {
	let id: String

	var dateAdded: Date
	var downloaded: Int64
	var downloadPath: String
	var downloadRate: Int64
	var eta: TimeInterval
	var hash: String
	var label: String
	var name: String
	var peers: Int
	var progress: Float
	var seeds: Int
	var size: Int64
	var state: TorrentState
	var totalPeers: Int
	var totalSeeds: Int
	var trackers: [String]
	var uploaded: Int64
	var uploadRate: Int64

	init(
		dateAdded: Date,
		downloaded: Int64,
		downloadPath: String,
		downloadRate: Int64,
		eta: TimeInterval,
		hash: String,
		label: String,
		name: String,
		peers: Int,
		progress: Float,
		seeds: Int,
		size: Int64,
		state: TorrentState,
		totalPeers: Int,
		totalSeeds: Int,
		trackers: [String],
		uploaded: Int64,
		uploadRate: Int64
	) {
		self.id = hash
		self.dateAdded = dateAdded
		self.downloaded = downloaded
		self.downloadPath = downloadPath
		self.downloadRate = downloadRate
		self.eta = eta
		self.hash = hash
		self.label = label
		self.name = name
		self.peers = peers
		self.progress = progress
		self.seeds = seeds
		self.size = size
		self.state = state
		self.totalPeers = totalPeers
		self.totalSeeds = totalSeeds
		self.trackers = trackers
		self.uploaded = uploaded
		self.uploadRate = uploadRate
	}

	func update(_ torrent: StandardTorrent) {
		guard self.hash == torrent.hash else {
			print("Warning: Attempting to update torrent with different hash. Current: \(self.hash), Other: \(torrent.hash)")
			return
		}
		
		self.dateAdded = torrent.dateAdded
		self.downloaded = torrent.downloaded
		self.downloadPath = torrent.downloadPath
		self.downloadRate = torrent.downloadRate
		self.eta = torrent.eta
		self.hash = torrent.hash
		self.label = torrent.label
		self.name = torrent.name
		self.peers = torrent.peers
		self.progress = torrent.progress
		self.seeds = torrent.seeds
		self.size = torrent.size
		self.state = torrent.state
		self.totalPeers = torrent.totalPeers
		self.totalSeeds = torrent.totalSeeds
		self.trackers = torrent.trackers
		self.uploaded = torrent.uploaded
		self.uploadRate = torrent.uploadRate
	}
}

extension StandardTorrent {
	var ratio: Double {
		Double(uploaded) / Double(downloaded)
	}

	var isActive: Bool {
		state == .downloading || state == .seeding
	}

	var localizedSpeed: String {
		if state == .downloading {
			let download = downloadRate.formatted(Formatters.bytes)
			let upload = uploadRate.formatted(Formatters.bytes)
			return L10n.Torrent.downloadUploadSpeed(downloadSpeed: download, uploadSpeed: upload)
		} else if state == .seeding {
			return L10n.Torrent.uploadSpeed(uploadRate.formatted(Formatters.bytes))
		} else {
			return ""
		}
	}

	var localizedProgress: String {
		L10n.Torrent.progress(
			downloaded: downloaded.formatted(Formatters.bytes),
			size: size.formatted(Formatters.bytes),
			progress: progress.formatted(Formatters.percentage)
		)
	}

	var formattedETA: String {
		eta > 0
		? Duration.seconds(eta).formatted(Formatters.eta)
		: L10n.Common.infinity
	}

	func formattedRatio(precision: Int = 1) -> String {
		guard !ratio.isInfinite, !ratio.isNaN else { return L10n.Common.infinity }
		return ratio.formatted(Formatters.float(precision: precision))
	}

	var localizedRatioOrETA: String {
		if state == .downloading {
			return formattedETA
		} else {
			return L10n.Torrent.ratio(formattedRatio())
		}
	}
}

extension StandardTorrent: Hashable, Equatable, Identifiable {
	static func == (lhs: StandardTorrent, rhs: StandardTorrent) -> Bool {
//		lhs.dateAdded == rhs.dateAdded &&
//		lhs.downloaded == rhs.downloaded &&
//		lhs.downloadPath == rhs.downloadPath &&
//		lhs.downloadRate == rhs.downloadRate &&
//		lhs.eta == rhs.eta &&
		lhs.hash == rhs.hash //&&
//		lhs.label == rhs.label &&
//		lhs.name == rhs.name &&
//		lhs.peers == rhs.peers &&
//		lhs.progress == rhs.progress &&
//		lhs.seeds == rhs.seeds &&
//		lhs.size == rhs.size &&
//		lhs.state == rhs.state &&
//		lhs.totalPeers == rhs.totalPeers &&
//		lhs.totalSeeds == rhs.totalSeeds &&
//		lhs.trackers == rhs.trackers &&
//		lhs.uploaded == rhs.uploaded &&
//		lhs.uploadRate == rhs.uploadRate
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(hash)
	}
}
