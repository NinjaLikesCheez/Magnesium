import Deluge
import Foundation

final class DelugeActionImplementation: TorrentClientActing {
	private let client: Deluge
	private let session: DelugeSession

	init(session: DelugeSession) {
		self.session = session
		self.client = session.client
	}

	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) {
		try await into { session.refresh() }
	}

	func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] {
		func torrentFiles(in items: [DelugeTorrentItem]) -> [StandardTorrentFile] {
			items.reduce(into: [StandardTorrentFile]()) { result, item in
				switch item {
				case .file(let file):
					result.append(file.standard)
				case .directory(_, let items):
					result.append(contentsOf: torrentFiles(in: items))
				}
			}
		}
		return torrentFiles(in: try await into { client.request(.torrentItems(hash: torrent.hash)) })
	}

	func addLink(_ url: String) async throws(TorrentClientError) {
		guard let url = URL(string: url) else {
			throw .invalidLinkAdded
		}

		if url.scheme == "magnet" {
			try await into { client.request(.add(magnetURL: url)) }
		} else {
			try await into { client.request(.add(fileURL: url)) }
		}
	}

	func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String] {
		func torrentPaths(in items: [DelugeTorrentItem]) -> [String] {
			items.reduce(into: [String]()) { result, item in
				switch item {
				case .file(let file):
					result.append(file.path)
				case .directory(let name, let items):
					result.append(name)
					result.append(contentsOf: torrentPaths(in: items))
				}
			}
		}
		// TODO: Make deluge use a cross import overlay so we don't get fucking combine all the time... : https://sundayswift.com/posts/cross-import-overlays/
		let items = try await into { client.request(.torrentItems(hash: torrent.hash)) }
		return torrentPaths(in: items)
	}

	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await into { client.request(.pause(hashes: torrents.map(\.hash))) }
	}

	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await into { client.request(.resume(hashes: torrents.map(\.hash))) }
	}

	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError) {
		try await into { client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData)) }
	}

	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await into { client.request(.recheck(hashes: torrents.map(\.hash))) }
	}

	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		await withThrowingTaskGroup(of: Void.self) { group in
			for torrent in torrents {
				group.addTask {
					try await self.client.request(.setLabel(hash: torrent.hash, label: label.name))
				}
			}
		}
	}

	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await into { client.request(.reannounce(hashes: torrents.map(\.hash))) }
	}

	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		try await into { client.request(.move(hashes: torrents.map(\.hash), path: path)) }
	}
}

//	request<Value: Decodable>(_ request: DelugeRequest<Value>) async throws(Deluge.Error) -> Value {
@discardableResult
fileprivate func into<ReturnType>(_ operation: () async throws(Deluge.Error) -> ReturnType) async throws(TorrentClientError) -> ReturnType {
	do throws(Deluge.Error) {
		return try await operation()
	} catch {
		throw .deluge(error)
	}
}

