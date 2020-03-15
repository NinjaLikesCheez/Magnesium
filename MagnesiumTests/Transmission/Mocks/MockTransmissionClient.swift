import Combine
import Foundation
@testable import Magnesium
import Transmission
import XCTest

final class MockTransmissionClient: TransmissionClient {
    private(set) var requestCallCount = 0
    private(set) var requestParamRequest = [Request<Any>]()
    var results = [(method: String, result: AnyPublisher<Any, TransmissionError>)]()
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, TransmissionError> {
        requestCallCount += 1
        requestParamRequest.append(request.map { $0 as Any })
        let response = results.compactMap { result -> AnyPublisher<Value, TransmissionError>? in
            guard result.method == request.method else { return nil }
            return result.result.map { $0 as! Value }.eraseToAnyPublisher()
        }.first
        return response ?? Fail(error: .unexpectedResponse).eraseToAnyPublisher()
    }
}

extension Request {
    var argsJSON: String {
        let data = try! JSONSerialization.data(withJSONObject: args, options: [.sortedKeys])
        return String(data: data, encoding: .utf8)!
    }
}
