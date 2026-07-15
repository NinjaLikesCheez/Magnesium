import CommonUI
import Observation
import SwiftUINavigation

/// Navigation + presentation state for the TorrentList feature, driven by swift-navigation
/// case-path bindings instead of the Router package.
///
/// `path` and `destination` are separate optionals (rather than one shared enum) because a
/// pushed detail screen and a presented error can be on-screen at the same time — e.g.
/// `TorrentDetailHeaderView` presents an error without popping. Sharing one optional would make
/// presenting an error silently dismiss the pushed detail view.
@Observable
public final class TorrentListModel {
	public var error: Error?
	public var destination: Destination?

	public init() {}

	/// Stack-navigation targets for the TorrentList feature.
	@CasePathable
	public enum Destination: Hashable {
		/// Navigate to the detailed view of a specific torrent
		case detail(StandardTorrent)
	}

	/// Modal error presentations for the TorrentList feature.
	@CasePathable
	public enum Error: Hashable {
		case clientError(TorrentClientError)
		case fileImportError(FileImportError) // fileImport API throws any Error... so manually build it
	}

	/// A file-import failure message. `id` is the message itself since these carry no other identity.
	public struct FileImportError: Hashable, Identifiable {
		public var id: String { message }
		public let message: String

		public init(_ message: String) {
			self.message = message
		}
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

extension TorrentClientError: Identifiable {
	public var id: Self { self }
}
