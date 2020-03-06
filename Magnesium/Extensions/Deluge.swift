import Combine
import Deluge
import Foundation

typealias DelugeError = Deluge.Client.Error
typealias DefaultDelugeClient = Deluge.Client
typealias DelugeTorrentFile = Deluge.TorrentFile
typealias DelugeLabel = Deluge.Label

protocol DelugeClient {
    func request<Value>(_ request: Deluge.Request<Value>) -> AnyPublisher<Value, DefaultDelugeClient.Error>
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
