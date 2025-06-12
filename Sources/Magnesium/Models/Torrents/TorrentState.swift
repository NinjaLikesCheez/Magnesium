import SwiftUI

enum TorrentState: String, Equatable, Hashable, Codable, CaseIterable, Identifiable {
	var id: Self { self }

	case downloading = "Downloading"
	case seeding = "Seeding"
	case paused = "Paused"
	case checking = "Checking"
	case queued = "Queued"
	case error = "Error"
}

extension TorrentState {
	var localizedString: String {
		switch self {
		case .downloading:
			return L10n.Torrent.downloadingState
		case .seeding:
			return L10n.Torrent.seedingState
		case .paused:
			return L10n.Torrent.pausedState
		case .queued:
			return L10n.Torrent.queuedState
		case .checking:
			return L10n.Torrent.checkingState
		case .error:
			return L10n.Torrent.errorState
		}
	}

	var progressColor: Color {
		switch self {
		case .seeding:
			return .green
		case .downloading:
			return .blue
		case .error:
			return .red
		case .queued, .checking:
			return .yellow
		case .paused:
			return .purple
		}
	}
}
