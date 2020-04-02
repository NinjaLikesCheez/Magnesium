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
        .init(index: index, name: name, size: size, progress: progress, priority: priority.standard)
    }
}

extension Priority {
    var standard: TorrentPriority {
        switch self {
        case .disabled:
            return .disabled
        case .low:
            return .low
        case .normal:
            return .normal
        case .high:
            return .high
        default:
            return .normal
        }
    }
}

extension TorrentPriority {
    var deluge: Priority {
        switch self {
        case .disabled:
            return .disabled
        case .low:
            return .low
        case .normal:
            return .normal
        case .high:
            return .high
        }
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
