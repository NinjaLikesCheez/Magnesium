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

extension Request where Value == ([DelugeTorrent], [DelugeLabel]) {
    private static let properties = [
        "name",
        "state",
        "time_added",
        "download_payload_rate",
        "upload_payload_rate",
        "eta",
        "progress",
        "total_done",
        "total_uploaded",
        "total_size",
        "num_seeds",
        "total_seeds",
        "num_peers",
        "total_peers",
        "trackers",
        "label",
        "download_location",
    ]

    static var updateUIForApp: Self {
        Request<([Torrent], [Label])>.updateUI(properties: properties)
            .map { ($0.compactMap(DelugeTorrent.init), $1) }
    }
}
