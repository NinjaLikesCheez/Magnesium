import Foundation
import QBittorrent

extension StandardTorrent {
	private static func state(for state: Torrent.State) -> TorrentState {
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

	init(_ torrent: Torrent) {
		hash = torrent.hash
		// TODO: convert QBT to declare Int64 instead of Int
		self.dateAdded = Date(timeIntervalSince1970: TimeInterval(torrent.addedOn))  // TODO: Decode as a date in QBittorrent
		self.downloaded = Int64(torrent.downloaded)
		self.downloadPath = torrent.downloadPath
		self.downloadRate = Int64(torrent.dlspeed)
		self.eta = TimeInterval(torrent.eta)
		if let firstTag = torrent.tags.split(separator: ",").first {
			self.label = String(firstTag)  // TODO: label needs to be updated to an array
		} else {
			self.label = ""
		}
		self.name = torrent.name
		self.peers = torrent.numLeechs
		self.progress = Float(torrent.progress)
		self.seeds = torrent.numSeeds
		self.size = Int64(torrent.size)
		self.state = Self.state(for: torrent.state)
		self.totalPeers = torrent.numIncomplete
		self.totalSeeds = torrent.numComplete
		self.trackers = [torrent.tracker]  // TODO: qbt only returns the first working tracker :/
		self.uploaded = Int64(torrent.uploaded)
		self.uploadRate = Int64(torrent.upspeed)
	}
}
