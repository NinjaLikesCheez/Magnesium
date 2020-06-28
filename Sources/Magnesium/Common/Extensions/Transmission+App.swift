import Combine
import Foundation
import Transmission

typealias TransmissionTorrentFile = TorrentFile

protocol TransmissionClient {
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, TransmissionError>
}

extension Transmission: TransmissionClient {}

extension TransmissionTorrentFile {
    var standard: StandardTorrentFile {
        .init(
            index: index,
            name: name,
            size: size,
            progress: Float(downloaded) / Float(size),
            priority: isWanted ? priority.standard : .disabled
        )
    }
}

extension Priority {
    var standard: TorrentPriority {
        switch self {
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

extension TransmissionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .encoding(error):
            return error.localizedDescription
        case let .decoding(error):
            return error.localizedDescription
        case let .filesystem(error):
            return error.localizedDescription
        case let .request(error):
            return error.localizedDescription
        case let .statusCode(statusCode):
            return L10n.Error.unexpectedStatusCode(statusCode)
        case .noSessionID:
            return L10n.Error.noSessionID
        case .unauthenticated:
            return L10n.Error.unauthenticatedVerifyCredentials
        case .unexpectedResponse:
            return L10n.Error.unexpectedServerResponse
        case let .serverError(result):
            if let result = result {
                return L10n.Error.serverErrorWithMessage(result)
            } else {
                return L10n.Error.serverError
            }
        }
    }
}
