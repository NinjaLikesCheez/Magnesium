import Combine
import Foundation
import Transmission

typealias TransmissionTorrentFile = TorrentFile

protocol TransmissionClient {
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, TransmissionError>
}

extension Transmission: TransmissionClient {}

extension TransmissionTorrentFile: StandardTorrentFile {
    var progress: Float {
        Float(downloaded) / Float(size)
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
            return L10n.unexpectedStatusCodeErrorDescription(statusCode)
        case .noSessionID:
            return L10n.noSessionIDErrorDescription
        case .unauthenticated:
            return L10n.unauthenticatedErrorDescription
        case .unexpectedResponse:
            return L10n.unexpectedResponseErrorDescription
        case let .serverError(result):
            if let result = result {
                return L10n.serverMessageErrorDescription(result)
            } else {
                return L10n.serverErrorDescription
            }
        }
    }
}
