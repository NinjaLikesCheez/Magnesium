import Deluge
import Foundation

extension TorrentActionImplementation {
	static func deluge(_ session: DelugeSession) -> Self {
		let client = session.client
		return .init(
			refresh: { try await refresh(session: session) },
			// detailViewModel: { detailViewModel(session: session, torrentSubject: $0, labelsSubject: $1) },
			addLink: { url async throws(AddLinkError) in try await addLink(client: client, url: url) },
			paths: { try await paths(client: client, torrent: $0) },
			pause: { try await pause(client: client, torrents: $0) },
			resume: { try await resume(client: client, torrents: $0) },
			remove: { try await remove(client: client, torrents: $0, removeData: $1) },
			verify: { try await verify(client: client, torrents: $0) },
			setLabel: { try await setLabel(client: client, label: $0, torrents: $1) },
			updateTrackers: { try await updateTrackers(client: client, torrents: $0) },
			moveDownloadFolder: { try await moveDownloadFolder(client: client, path: $0, torrents: $1) }
		)
	}

	private static func refresh(session: DelugeSession) async throws -> ([StandardTorrent], [StandardLabel]) {
		try await session.refresh()
	}

	// private static func detailViewModel(
	// 	session: DelugeSession,
	// 	torrentSubject: CurrentValueSubject<StandardTorrent, Never>,
	// 	labelsSubject: CurrentValueSubject<[StandardLabel], Never>
	// ) -> AnyTorrentDetailViewModel {
	// 	let viewModel = StandardTorrentDetailViewModel(
	// 		implementation: .deluge(session: session),
	// 		torrentSubject: torrentSubject,
	// 		labelsSubject: labelsSubject
	// 	)
	// 	return AnyViewModel(viewModel)
	// }

	private static func addLink(
		client: Deluge,
		url: String
	) async throws(AddLinkError) {
		guard let url = URL(string: url) else {
			throw .init(
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
			throw .init(
				title: L10n.Error.failedToAddTorrent,
				message: L10n.Error.serverErrorWithMessage(error.localizedDescription)
			)
		}
	}

	private static func torrentPaths(in items: [DelugeTorrentItem]) -> [String] {
			items.reduce(into: [String]()) { result, item in
					switch item {
					case let .file(file):
							result.append(file.path)
					case let .directory(name, items):
							result.append(name)
							result.append(contentsOf: torrentPaths(in: items))
					}
			}
	}

	private static func paths(client: Deluge, torrent: StandardTorrent) async throws -> [String] {
		let items = try await client.request(.torrentItems(hash: torrent.hash))
		return torrentPaths(in: items)
	}

	private static func pause(client: Deluge, torrents: [StandardTorrent]) async throws {
		try await client.request(.pause(hashes: torrents.map(\.hash)))
	}

	private static func resume(client: Deluge, torrents: [StandardTorrent]) async throws {
		try await client.request(.resume(hashes: torrents.map(\.hash)))
	}

	private static func remove(
		client: Deluge,
		torrents: [StandardTorrent],
		removeData: Bool
	) async throws {
		try await client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData))
	}

	private static func verify(client: Deluge, torrents: [StandardTorrent]) async throws {
		try await client.request(.recheck(hashes: torrents.map(\.hash)))
	}

	private static func setLabel(
		client: Deluge,
		label: StandardLabel,
		torrents: [StandardTorrent]
	) async throws {
		await withThrowingTaskGroup(of: Void.self) { group in
			for torrent in torrents {
				group.addTask {
					try await client.request(.setLabel(hash: torrent.hash, label: label.name))
				}
			}
		}
	}

	private static func updateTrackers(client: Deluge, torrents: [StandardTorrent]) async throws {
		try await client.request(.reannounce(hashes: torrents.map(\.hash)))
	}

	private static func moveDownloadFolder(
		client: Deluge,
		path: String,
		torrents: [StandardTorrent]
	) async throws {
		try await client.request(.move(hashes: torrents.map(\.hash), path: path))
	}
}
