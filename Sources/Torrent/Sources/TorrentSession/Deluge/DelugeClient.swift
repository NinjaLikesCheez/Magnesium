import Deluge
import Foundation

final class DelugeClient: TorrentClient {
	private let client: Deluge
	private let session: DelugeSession

	init(session: DelugeSession) {
		self.session = session
		self.client = session.client
	}

	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) {
		do {
			let torrentsAndLabels = try await client.request(.updateUIForApp)

			return await MainActor.run {
				let torrents = torrentsAndLabels.torrents.compactMap(StandardTorrent.init)
				let labels = torrentsAndLabels.labels.map(StandardLabel.init)

				return (torrents, labels)
			}
		} catch {
			throw .deluge(error)
		}
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
		do {
			return torrentFiles(in: try await client.request(.torrentItems(hash: torrent.hash)))
		} catch {
			throw .deluge(error)
		}
	}

	func addLink(_ url: String) async throws(TorrentClientError) {
		guard let url = URL(string: url) else {
			throw .invalidLinkAdded
		}

		do {
			if url.scheme == "magnet" {
				try await client.request(.add(magnetURL: url))
			} else {
				try await client.request(.add(fileURL: url))
			}
		} catch {
			throw .deluge(error)
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
		do {
			let items = try await client.request(.torrentItems(hash: torrent.hash))
			return torrentPaths(in: items)
		} catch {
			throw .deluge(error)
		}
	}

	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		do {
			try await client.request(.pause(hashes: torrents.map(\.hash)))
		} catch {
			throw .deluge(error)
		}
	}

	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		do {
			try await client.request(.resume(hashes: torrents.map(\.hash)))
		} catch {
			throw .deluge(error)
		}
	}

	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError) {
		do {
			try await client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData))
		} catch {
			throw .deluge(error)
		}
	}

	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		do {
			try await client.request(.recheck(hashes: torrents.map(\.hash)))
		} catch {
			throw .deluge(error)
		}
	}

	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		for torrent in torrents {
			do throws(Deluge.Error) {
				try await self.client.request(.setLabel(hash: torrent.hash, label: label.name))
			} catch {
				throw .deluge(error)
			}
		}
	}

	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		do {
			try await client.request(.reannounce(hashes: torrents.map(\.hash)))
		} catch {
			throw .deluge(error)
		}
	}

	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError) {
		do {
			try await client.request(.move(hashes: torrents.map(\.hash), path: path))
		} catch {
			throw .deluge(error)
		}
	}
}
