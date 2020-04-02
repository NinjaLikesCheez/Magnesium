import Combine
import Deluge
import Foundation

typealias DelugeTorrentFile = TorrentFile
typealias DelugeLabel = Label
typealias DelugeTorrentItem = TorrentItem

protocol DelugeClient {
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, DelugeError>
}

extension Deluge: DelugeClient {}

extension DelugeTorrentFile {
    var standard: StandardTorrentFile {
        .init(index: index, name: name, size: size, progress: progress)
    }
}

extension DelugeLabel {
    var standard: StandardLabel {
        .init(name: name, count: count)
    }
}

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
