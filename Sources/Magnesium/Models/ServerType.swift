enum ServerType: String, Identifiable, CaseIterable, Codable {
	case deluge = "Deluge"
	// case transmission
	case qbittorrent = "QBittorrent"

	var id: Self { self }
}

extension ServerType {
	var localizedString: String {
		switch self {
		case .deluge:
			return L10n.Server.deluge
		// case .transmission:
		// 	return L10n.Server.transmission
		case .qbittorrent:
			return L10n.Server.qbittorrent
		}
	}
}
