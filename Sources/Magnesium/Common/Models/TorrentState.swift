import UIKit

enum TorrentState: String {
    case downloading
    case seeding
    case paused
    case checking
    case queued
    case error
}

extension TorrentState: CaseIterable {}
extension TorrentState: Codable {}
extension TorrentState: Equatable {}
extension TorrentState: Hashable {}

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

    var displayColor: UIColor {
        switch self {
        case .seeding:
            return .systemGreen
        case .downloading:
            return .systemBlue
        case .error:
            return .systemRed
        case .queued, .checking:
            return .systemYellow
        case .paused:
            return .systemPurple
        }
    }
}
