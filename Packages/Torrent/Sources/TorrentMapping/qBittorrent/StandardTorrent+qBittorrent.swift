import Foundation
import QBittorrent

public extension StandardTorrent {
	private static func state(for state: Torrent.State) -> StandardTorrentState {
		switch state {
		case .error:
			.error
		case .missingFiles:
			.error
		case .uploading:
			.seeding
		case .stoppedUpload:
			.paused
		case .queuedUpload:
			.queued
		case .stalledUpload:
			.seeding
		case .checkingUpload:
			.checking
		case .forcedUpload:
			.seeding
		case .downloading:
			.downloading
		case .metaDownload:
			.downloading
		case .stoppedDownload:
			.paused
		case .queuedDownload:
			.queued
		case .stalledDownload:
			.error
		case .checkingDownload:
			.checking
		case .forcedDownload:
			.downloading
		case .checkingResumeData:
			.checking
		case .moving:
			.checking
		case .unknown:
			.error
		case .forcedMetaDownload:
			.downloading
		}
	}

	convenience init(_ torrent: Torrent) {
		self.init(
			dateAdded: Date(timeIntervalSince1970: TimeInterval(torrent.addedOn)),
			downloaded: Int64(torrent.downloaded),
			downloadPath: torrent.downloadPath,
			downloadRate: Int64(torrent.dlspeed),
			eta: TimeInterval(torrent.eta),
			hash: torrent.hash,
			label: torrent.tags.split(separator: ",").first.map(String.init) ?? "",
			name: torrent.name,
			peers: torrent.numLeechs,
			progress: Float(torrent.progress),
			seeds: torrent.numSeeds,
			seedingTime: TimeInterval(torrent.seedingTime),
			size: Int64(torrent.size),
			state: Self.state(for: torrent.state),
			totalPeers: torrent.numIncomplete,
			totalSeeds: torrent.numComplete,
			trackers: [torrent.tracker],
			uploaded: Int64(torrent.uploaded),
			uploadRate: Int64(torrent.upspeed)
		)
	}
}
