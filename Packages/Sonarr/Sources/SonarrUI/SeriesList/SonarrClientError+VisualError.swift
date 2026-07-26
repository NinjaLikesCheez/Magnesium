import Common
import SonarrSession

// TODO: Sonarr.Error (APIClient.ClientError<SonarrResponseError>) isn't Equatable/Hashable
// upstream, so this can't switch on it structurally the way TorrentClientError does for
// Deluge/QBittorrent errors — falls back to localizedDescription until swift-api-client exposes
// something more specific to match on.
extension SonarrClientError: VisualError {
	public var title: String {
		switch self {
		case .nullImplementation:
			"No Server Configured"
		case .sonarr:
			"Sonarr Error"
		}
	}

	public var systemName: String {
		switch self {
		case .nullImplementation:
			"exclamationmark.triangle"
		case .sonarr:
			"network.slash"
		}
	}

	public var subtitle: String {
		switch self {
		case .nullImplementation:
			"No Sonarr server is configured yet."
		case let .sonarr(error):
			"\(error)"
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case .nullImplementation:
			hasher.combine("nullImplementation")
		case let .sonarr(error):
			hasher.combine("sonarr")
			hasher.combine("\(error)")
		}
	}
}

extension SonarrClientError: Equatable {
	public static func == (lhs: SonarrClientError, rhs: SonarrClientError) -> Bool {
		switch (lhs, rhs) {
		case (.nullImplementation, .nullImplementation):
			true
		case let (.sonarr(lhsError), .sonarr(rhsError)):
			"\(lhsError)" == "\(rhsError)"
		default:
			false
		}
	}
}

extension SonarrClientError: Identifiable {
	public var id: Self { self }
}
