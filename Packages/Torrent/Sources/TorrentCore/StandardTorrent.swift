import Common
import Foundation
import Observation

@MainActor
@Observable
public final class StandardTorrent {
	public let id: String

	public private(set) var dateAdded: Date
	public private(set) var downloaded: Int64
	public private(set) var downloadPath: String
	public private(set) var downloadRate: Int64
	public private(set) var eta: TimeInterval
	public private(set) var hash: String
	public private(set) var label: String
	public private(set) var name: String
	public private(set) var peers: Int
	public private(set) var progress: Float
	public private(set) var seeds: Int
	public private(set) var size: Int64
	public private(set) var state: StandardTorrentState
	public private(set) var totalPeers: Int
	public private(set) var totalSeeds: Int
	public private(set) var trackers: [String]
	public private(set) var uploaded: Int64
	public private(set) var uploadRate: Int64

	public init(
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
		state: StandardTorrentState,
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

	// TODO: Can we use spi to make this internal and then have the torrent manager use it?
	public func update(_ torrent: StandardTorrent) {
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
	public var ratio: Double {
		Double(uploaded) / Double(downloaded)
	}

	public var isActive: Bool {
		state == .downloading || state == .seeding
	}

	public var localizedSpeed: String {
		let download = downloadRate.formatted(Formatters.bytes)
		let upload = uploadRate.formatted(Formatters.bytes)

		return switch state {
		case .downloading:
			"↓ \(download)/s ↑ \(upload)/s"
		case .seeding:
			"↑ \(upload)/s"
		default:
			""
		}
	}

	public var localizedProgress: String {
		let downloaded = self.downloaded.formatted(Formatters.bytes)
		let size = self.size.formatted(Formatters.bytes)
		let progress = self.progress.formatted(Formatters.percentage)

		return "\(downloaded) / \(size) (\(progress))"
	}

	public var formattedETA: String {
		eta > 0
			? Duration.seconds(eta).formatted(Formatters.eta)
			: "∞"
	}

	public func formattedRatio(precision: Int = 1) -> String {
		guard !ratio.isInfinite, !ratio.isNaN else { return "∞" }

		return ratio.formatted(Formatters.float(precision: precision))
	}

	public var localizedRatioOrETA: String {
		if state == .downloading {
			return formattedETA
		} else {
			return "Ratio: \(formattedRatio())"
		}
	}
}

extension StandardTorrent: @MainActor Hashable, @MainActor Equatable, Identifiable {
	public static func == (lhs: StandardTorrent, rhs: StandardTorrent) -> Bool {
		lhs.hash == rhs.hash
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(hash)
	}
}
