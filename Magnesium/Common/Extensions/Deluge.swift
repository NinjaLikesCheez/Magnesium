import Combine
import Deluge
import Foundation

typealias DefaultDelugeClient = Deluge
typealias DelugeTorrentFile = TorrentFile
typealias DelugeLabel = Label

protocol DelugeClient {
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, DelugeError>
}

extension DefaultDelugeClient: DelugeClient {}
extension DelugeTorrentFile: StandardTorrentFile {}
extension DelugeLabel: StandardLabel {}

extension DelugeError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .encoding(error):
            return error.localizedDescription
        case let .decoding(error):
            return error.localizedDescription
        case let .request(error):
            return error.localizedDescription
        case .unauthenticated:
            return L10n.unauthenticatedErrorDescription
        case .unexpectedResponse:
            return L10n.unexpectedResponseErrorDescription
        case let .serverError(message):
            if let message = message {
                return L10n.serverMessageErrorDescription(message)
            } else {
                return L10n.serverErrorDescription
            }
        }
    }
}

extension Request {
    static var updateUIForApp: Request<([DelugeTorrent], [DelugeLabel])> {
        let properties: [Torrent.PropertyKeys] = [
            .dateAdded,
            .downloaded,
            .downloadPath,
            .downloadRate,
            .eta,
            .label,
            .name,
            .peers,
            .progress,
            .seeds,
            .size,
            .state,
            .totalPeers,
            .totalSeeds,
            .trackers,
            .uploaded,
            .uploadRate,
        ]

        return Self.updateUI(properties: properties).map { ($0.compactMap(DelugeTorrent.init), $1) }
    }
}
