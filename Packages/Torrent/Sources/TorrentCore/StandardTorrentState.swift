import SwiftUI

public enum StandardTorrentState: String, Equatable, Hashable, Codable, CaseIterable, Identifiable {
	public var id: Self { self }

	case downloading = "Downloading"
	case seeding = "Seeding"
	case paused = "Paused"
	case checking = "Checking"
	case queued = "Queued"
	case error = "Error"
}

extension StandardTorrentState {
	public var localizedString: String {
		rawValue
	}

	public var progressColor: Color {
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
