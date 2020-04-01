import Combine
import Foundation
@testable import Magnesium
import SnapshotTesting
import Transmission
import XCTest

final class MockTransmissionClient: TransmissionClient {
    private(set) var requestCallCount = 0
    private(set) var requests = [Request<Any>]()
    var results = [(method: String, result: AnyPublisher<Any, TransmissionError>)]()
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, TransmissionError> {
        requestCallCount += 1
        requests.append(request.map { $0 as Any })
        let response = results.compactMap { result -> AnyPublisher<Value, TransmissionError>? in
            guard result.method == request.method else { return nil }
            return result.result.map { $0 as! Value }.eraseToAnyPublisher()
        }.first
        return response ?? Fail(error: .unexpectedResponse).eraseToAnyPublisher()
    }
}

extension Snapshotting where Value == [Request<Any>], Format == String {
    static var requests: Snapshotting {
        .init(
            pathExtension: "json",
            diffing: .lines,
            snapshot: { requests in
                let json: [[String: Any]] = requests.map { ["method": $0.method, "args": $0.args] }
                let data = try! JSONSerialization.data(
                    withJSONObject: json,
                    options: [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes]
                )
                return String(data: data, encoding: .utf8)!
            }
        )
    }
}
