import Foundation
import Deluge

enum TorrentClientError: VisualError {
	/// Represents an error thrown by the Null Implementation (a testing implementation, this should not happen in production)
	case nullImplementation

	case invalidLinkAdded

	case deluge(Deluge.Error)
}

protocol TorrentClientActing: AnyObject {
	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel])
	func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile]
	func addLink(_ url: String) async throws(TorrentClientError)
	func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String]
	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError)
	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError)
}

final class NullTorrentActionImplementation: TorrentClientActing {
	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) { throw .nullImplementation }
	func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] { throw .nullImplementation }
	func addLink(_ url: String) async throws(TorrentClientError) { throw .nullImplementation }
	func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String] { throw .nullImplementation }
	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError) { throw .nullImplementation }
	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
}
