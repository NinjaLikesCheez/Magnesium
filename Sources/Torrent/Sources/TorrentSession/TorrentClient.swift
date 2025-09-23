import Common
import Deluge
import QBittorrent

public protocol TorrentClient: AnyObject {
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

public final class NullTorrentClient: TorrentClient {
	public func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) {
		throw .nullImplementation
	}
	public func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] {
		throw .nullImplementation
	}
	public func addLink(_ url: String) async throws(TorrentClientError) { throw .nullImplementation }
	public func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String] {
		throw .nullImplementation
	}
	public func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	public func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	public func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError) {
		throw .nullImplementation
	}
	public func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	public func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		throw .nullImplementation
	}
	public func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		throw .nullImplementation
	}
	public func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		throw .nullImplementation
	}
}
