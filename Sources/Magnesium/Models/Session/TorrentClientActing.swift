import Foundation

protocol TorrentClientActing: AnyObject {
	associatedtype AddLinkError: Error
	func refresh() async throws -> ([StandardTorrent], [StandardLabel])
	func refreshFiles(_ torrent: StandardTorrent) async throws -> [StandardTorrentFile]
	func addLink(_ url: String) async throws(AddLinkError)
	func paths(_ torrent: StandardTorrent) async throws -> [String]
	func pause(_ torrents: [StandardTorrent]) async throws
	func resume(_ torrents: [StandardTorrent]) async throws
	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws
	func verify(_ torrents: [StandardTorrent]) async throws
	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws
	func updateTrackers(_ torrents: [StandardTorrent]) async throws
	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws
}

struct DefaultAddLinkError: Error {
	let title: String
	let message: String
}

final class NullTorrentActionImplementation: TorrentClientActing {
	struct NotReadyError: Error {}
	typealias AddLinkError = DefaultAddLinkError
	func refresh() async throws -> ([StandardTorrent], [StandardLabel]) { throw NotReadyError() }
	func refreshFiles(_ torrent: StandardTorrent) async throws -> [StandardTorrentFile] { throw NotReadyError() }
	func addLink(_ url: String) async throws(AddLinkError) {
		throw DefaultAddLinkError(title: "Not Ready", message: "Torrent actions are not ready.")
	}
	func paths(_ torrent: StandardTorrent) async throws -> [String] { throw NotReadyError() }
	func pause(_ torrents: [StandardTorrent]) async throws { throw NotReadyError() }
	func resume(_ torrents: [StandardTorrent]) async throws { throw NotReadyError() }
	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws { throw NotReadyError() }
	func verify(_ torrents: [StandardTorrent]) async throws { throw NotReadyError() }
	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws { throw NotReadyError() }
	func updateTrackers(_ torrents: [StandardTorrent]) async throws { throw NotReadyError() }
	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws { throw NotReadyError() }
}
