import QBittorrent

struct QBittorrentSession {
	let client: QBittorrent
	let torrents = [StandardTorrent]()

	func refresh() async throws -> [StandardTorrent] {
		try await client.request(.torrents()).map(StandardTorrent.init)
	}
}
