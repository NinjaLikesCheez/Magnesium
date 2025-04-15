import Observation

@Observable
class TorrentActionImplementation {
	struct AddLinkError: Error {
		let title: String
		let message: String
	}

	// var updatePublisher: AnyPublisher<([StandardTorrent], [StandardLabel]), Never>
	var refresh: () async throws -> ([StandardTorrent], [StandardLabel])
	var refreshFiles: (StandardTorrent) async throws -> [StandardTorrentFile]
	// var detailViewModel:
	// 	(
	// 		CurrentValueSubject<StandardTorrent, Never>,
	// 		CurrentValueSubject<[StandardLabel], Never>
	// 	) -> AnyTorrentDetailViewModel
	var addLink: (String) async throws(AddLinkError) -> Void
	var paths: (StandardTorrent) async throws -> [String]
	var pause: ([StandardTorrent]) async throws -> Void
	var resume: ([StandardTorrent]) async throws -> Void
	var remove: ([StandardTorrent], Bool) async throws -> Void
	var verify: ([StandardTorrent]) async throws -> Void
	var setLabel: (StandardLabel, [StandardTorrent]) async throws -> Void
	var updateTrackers: ([StandardTorrent]) async throws -> Void
	var moveDownloadFolder: (String, [StandardTorrent]) async throws -> Void

	required init(
		refresh: @escaping () async throws -> ([StandardTorrent], [StandardLabel]),
		refreshFiles: @escaping (StandardTorrent) async throws -> [StandardTorrentFile],
		addLink: @escaping (String) async throws(AddLinkError) -> Void,
		paths: @escaping (StandardTorrent) async throws -> [String],
		pause: @escaping ([StandardTorrent]) async throws -> Void,
		resume: @escaping ([StandardTorrent]) async throws -> Void,
		remove: @escaping ([StandardTorrent], Bool) async throws -> Void,
		verify: @escaping ([StandardTorrent]) async throws -> Void,
		setLabel: @escaping (StandardLabel, [StandardTorrent]) async throws -> Void,
		updateTrackers: @escaping ([StandardTorrent]) async throws -> Void,
		moveDownloadFolder: @escaping (String, [StandardTorrent]) async throws -> Void
	) {
		self.refresh = refresh
		self.refreshFiles = refreshFiles
		self.addLink = addLink
		self.paths = paths
		self.pause = pause
		self.resume = resume
		self.remove = remove
		self.verify = verify
		self.setLabel = setLabel
		self.updateTrackers = updateTrackers
		self.moveDownloadFolder = moveDownloadFolder
	}
}
