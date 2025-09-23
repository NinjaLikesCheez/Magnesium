import Foundation
import Deluge
import Common

enum TorrentClientError: VisualError {
	/// Represents an error thrown by the Null Implementation (a testing implementation, this should not happen in production)
	case nullImplementation

	case invalidLinkAdded

	case deluge(Deluge.Error)
}

//extension TorrentClientError: Equatable {
//	public static func == (lhs: TorrentClientError, rhs: TorrentClientError) -> Bool {
//		switch (lhs, rhs) {
//		case (.nullImplementation, .nullImplementation):
//			return true
//		case (.invalidLinkAdded, .invalidLinkAdded):
//			return true
//		case let (.deluge(lhsError), .deluge(rhsError)):
//			return lhsError == rhsError
//		default:
//			return false
//		}
//	}
//}
//
//extension TorrentClientError: Hashable {
//	public func hash(into hasher: inout Hasher) {
//		switch self {
//		case .nullImplementation:
//			hasher.combine(0)
//		case .invalidLinkAdded:
//			hasher.combine(1)
//		case .deluge(let error):
//			hasher.combine(2)
//			hasher.combine(error)
//		}
//	}
//}

extension TorrentClientError {
	var title: String {
		switch self {
		case .nullImplementation:
			"Null Implementation"
		case .invalidLinkAdded:
			"Invalid Link"
		case let .deluge(error):
			error.title
		}
	}

	var systemName: String {
		switch self {
		case .nullImplementation:
			"square.slash"
		case .invalidLinkAdded:
			"link"
		case let .deluge(error):
			error.systemName
		}
	}

	var subtitle: String {
		switch self {
		case .nullImplementation:
			"Null implementation called. This should only be used in testing"
		case .invalidLinkAdded:
			"The link was invalid. Please check it and try again"
		case let .deluge(error):
			error.subtitle
		}
	}
}

protocol TorrentClientActing: AnyObject {
	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel])
	func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile]
	func addLink(_ url: String) async throws(TorrentClientError)
	func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String]
	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError)
	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError)
	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError)
}

final class NullTorrentActionImplementation: TorrentClientActing {
	func refresh() async throws(TorrentClientError) -> ([StandardTorrent], [StandardLabel]) { throw .nullImplementation }
	func refreshFiles(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [StandardTorrentFile] { throw .nullImplementation }
	func addLink(_ url: String) async throws(TorrentClientError) { throw .nullImplementation }
	func paths(_ torrent: StandardTorrent) async throws(TorrentClientError) -> [String] { throw .nullImplementation }
	func pause(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func resume(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func remove(_ torrents: [StandardTorrent], _ removeData: Bool) async throws(TorrentClientError) { throw .nullImplementation }
	func verify(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func setLabel(_ label: StandardLabel, _ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func updateTrackers(_ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
	func moveDownloadFolder(_ path: String, _ torrents: [StandardTorrent]) async throws(TorrentClientError) { throw .nullImplementation }
}
