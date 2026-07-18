import Foundation

extension L10n {
	enum Torrent {
		static func downloadSpeed(_ downloadSpeed: String) -> String {
			let format = NSLocalizedString("torrent.download-speed", comment: "↓ {bytes}/s")
			return .localizedStringWithFormat(format, downloadSpeed)
		}

		static func uploadSpeed(_ uploadSpeed: String) -> String {
			let format = NSLocalizedString("torrent.upload-speed", comment: "↑ {bytes}/s")
			return .localizedStringWithFormat(format, uploadSpeed)
		}

		static func downloadUploadSpeed(downloadSpeed: String, uploadSpeed: String) -> String {
			let format = NSLocalizedString("torrent.download-upload-speed", comment: "↓ {bytes}/s ↑ {bytes}/s")
			return .localizedStringWithFormat(format, downloadSpeed, uploadSpeed)
		}

		static func progress(downloaded: String, size: String, progress: String) -> String {
			let format = NSLocalizedString("torrent.progress", comment: "{downloaded} / {size} ({percentage})")
			return .localizedStringWithFormat(format, downloaded, size, progress)
		}

		static func ratio(_ ratio: String) -> String {
			let format = NSLocalizedString("torrent.ratio", comment: "Ratio: {number}")
			return .localizedStringWithFormat(format, ratio)
		}

		static func torrentStatusWithPercentage(status: String, progress: String) -> String {
			let format = NSLocalizedString("torrent.status-with-percentage", comment: "{status} ({percentage})")
			return .localizedStringWithFormat(format, status, progress)
		}

		static func peers(peers: Int, totalPeers: Int) -> String {
			let format = NSLocalizedString("torrent.peers", comment: "{connectedPeers} ({totalPeers})")
			return .localizedStringWithFormat(format, peers, totalPeers)
		}

		static var downloadingState: String {
			NSLocalizedString("torrent.downloading-state", comment: "Downloading")
		}

		static var seedingState: String {
			NSLocalizedString("torrent.seeding-state", comment: "Seeding")
		}

		static var pausedState: String {
			NSLocalizedString("torrent.paused-state", comment: "Paused")
		}

		static var queuedState: String {
			NSLocalizedString("torrent.queued-state", comment: "Queued")
		}

		static var checkingState: String {
			NSLocalizedString("torrent.checking-state", comment: "Checking")
		}

		static var errorState: String {
			NSLocalizedString("torrent.error-state", comment: "Error")
		}

		static var removeKeepData: String {
			NSLocalizedString("torrent.remove-keep-data", comment: "Keep Data")
		}

		static var removeRemoveData: String {
			NSLocalizedString("torrent.remove-remove-data", comment: "Remove Data")
		}

		static func count(_ count: Int) -> String {
			let format = NSLocalizedString("torrent.count", comment: "{number} Torrents")
			return .localizedStringWithFormat(format, count)
		}

		static func networkSpeed(_ speed: String) -> String {
			let format = NSLocalizedString("torrent.network-speed", comment: "{bytes}/s")
			return .localizedStringWithFormat(format, speed)
		}
	}
}
