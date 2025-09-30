import SwiftUI

struct TorrentListItem: Identifiable {
	var id: String { hash }

	let hash: String
	let name: String
	let label: String
	let progress: Float
	let progressColor: Color
	let status: String
	let speed: String
	let progressText: String
	let ratioOrETA: String

	@MainActor
	init(torrent: StandardTorrent) {
		self.hash = torrent.hash
		self.name = torrent.name
		self.label = torrent.label
		self.progress = torrent.progress
		self.progressColor = torrent.state.progressColor
		self.status = torrent.state.localizedString
		self.speed = torrent.localizedSpeed
		self.progressText = torrent.localizedProgress
		self.ratioOrETA = torrent.localizedRatioOrETA
	}
}
