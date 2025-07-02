import Deluge
import Foundation

final class DelugeActionImplementation: TorrentClientActing {
	typealias AddLinkError = DefaultAddLinkError
	private let client: Deluge
	private let session: DelugeSession

	init(session: DelugeSession) {
		self.session = session
		self.client = session.client
	}

	func refresh() async throws -> ([StandardTorrent], [StandardLabel]) {
		try await session.refresh()
	}

	func refreshFiles(_ torrent: StandardTorrent) async throws -> [StandardTorrentFile] {
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
		return torrentFiles(in: try await client.request(.torrentItems(hash: torrent.hash)))
	}

	func addLink(_ url: String) async throws(AddLinkError) {
		guard let url = URL(string: url) else {
			throw AddLinkError(
				title: L10n.Error.invalidURL,
				message: L10n.Error.invalidURLMessage
			)
		}
		do {
			if url.scheme == "magnet" {
				try await client.request(.add(magnetURL: url))
			} else {
				try await client.request(.add(fileURL: url))
			}
		} catch {
			throw AddLinkError(
				title: L10n.Error.failedToAddTorrent,
				message: L10n.Error.serverErrorWithMessage(error.localizedDescription)
			)
		}
	}

	func paths(_ torrent: StandardTorrent) async throws -> [String] {
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
		let items = try await client.request(.torrentItems(hash: torrent.hash))
		return torrentPaths(in: items)
	}

	func pause(_ torrents: [StandardTorrent]) async throws {
		try await client.request(.pause(hashes: torrents.map(\.hash)))
	}

	func resume(_ torrents: [StandardTorrent]) async throws {
		try await client.request(.resume(hashes: torrents.map(\.hash)))
	}

	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws {
		try await client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData))
	}

	func verify(_ torrents: [StandardTorrent]) async throws {
		try await client.request(.recheck(hashes: torrents.map(\.hash)))
	}

	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws {
		await withThrowingTaskGroup(of: Void.self) { group in
			for torrent in torrents {
				group.addTask {
					try await self.client.request(.setLabel(hash: torrent.hash, label: label.name))
				}
			}
		}
	}

	func updateTrackers(_ torrents: [StandardTorrent]) async throws {
		try await client.request(.reannounce(hashes: torrents.map(\.hash)))
	}

	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws {
		try await client.request(.move(hashes: torrents.map(\.hash), path: path))
	}
}
