public enum TorrentServerType: String, Identifiable, CaseIterable, Codable, Sendable {
	public var id: Self { self }

	case deluge = "Deluge"
	case qbittorrent = "qBittorrent"
}

public extension TorrentServerType {
	var localizedString: String {
		rawValue
	}
}
