import Router
import SwiftUI
import CommonUI

public enum TorrentListError: RoutableError {
	public var id: Self { self }

	case clientError(TorrentClientError)
	case fileImportError(String) // fileImport API throws any Error... so manually build it
}

struct TorrentListErrorModifier: RoutableErrorViewModifier {
	@Binding var router: TorrentListRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .clientError(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
					)
				case let .fileImportError(message):
					PanelCard(
						title: "File Import Error",
						systemName: "square.and.arrow.down.badge.xmark",
						subtitle: message,
						primaryButtonAction: router.dismissError
					)
				}
			}
	}
}

extension View {
	func withTorrentListErrors(router: Binding<TorrentListRouter>) -> some View {
		modifier(TorrentListErrorModifier(router: router))
	}
}

extension TorrentClientError: VisualError {
	public var title: String {
		switch self {
		case .nullImplementation:
			return "Null Implementation"
		case .invalidLinkAdded:
			return "Invalid Link"
		case let .deluge(delugeError):
			return delugeError.title
		case let .qbittorrent(qbitError):
			return qbitError.title
		}
	}
	
	public var systemName: String {
		switch self {
		case .nullImplementation:
			return "exclamationmark.triangle"
		case .invalidLinkAdded:
			return "link"
		case let .deluge(delugeError):
			return delugeError.systemName
		case let .qbittorrent(qbitError):
			return qbitError.systemName
		}
	}
	
	public var subtitle: String {
		switch self {
		case .nullImplementation:
			return "No torrent client implementation is configured."
		case .invalidLinkAdded:
			return "The provided link is not a valid magnet or .torrent URL."
		case let .deluge(delugeError):
			return delugeError.subtitle
		case let .qbittorrent(qbitError):
			return qbitError.subtitle
		}
	}
	
	public func hash(into hasher: inout Hasher) {
		switch self {
		case .nullImplementation:
			hasher.combine("nullImplementation")
		case .invalidLinkAdded:
			hasher.combine("invalidLinkAdded")
		case let .deluge(delugeError):
			hasher.combine("deluge")
			hasher.combine(delugeError.title)
			hasher.combine(delugeError.subtitle)
			hasher.combine(delugeError.systemName)
		case let .qbittorrent(qbitError):
			hasher.combine("qbittorrent")
			hasher.combine(qbitError.title)
			hasher.combine(qbitError.subtitle)
			hasher.combine(qbitError.systemName)
		}
	}
}

// MARK: - Torrent client errors
// TODO: Move this into Torrent and make Deluge and QBittorrent errors equatable and hashable...
extension TorrentClientError: Equatable {
	public static func == (lhs: TorrentClientError, rhs: TorrentClientError) -> Bool {
		switch (lhs, rhs) {
		case (.nullImplementation, .nullImplementation):
			true
		case (.invalidLinkAdded, .invalidLinkAdded):
			true
		case let (.deluge(lhsError), .deluge(rhsError)):
			lhsError == rhsError
		case let (.qbittorrent(lhsError), .qbittorrent(rhsError)):
			lhsError == rhsError
		default:
			false
		}
	}
}
