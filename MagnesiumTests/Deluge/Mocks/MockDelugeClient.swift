import Combine
import Deluge
import Foundation
@testable import Magnesium

final class MockDelugeClient: DelugeClient {
    private(set) var requestCallCount = 0
    private(set) var requestParamRequest = [Request<Any>]()
    var results = [(method: String, result: AnyPublisher<Any, DelugeError>)]()
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, DelugeError> {
        requestCallCount += 1
        requestParamRequest.append(request.map { $0 as Any })
        let response = results.compactMap { result -> AnyPublisher<Value, DelugeError>? in
            guard result.method == request.method else { return nil }
            return result.result.map { $0 as! Value }.eraseToAnyPublisher()
        }.first
        return response ?? Fail(error: .unexpectedResponse).eraseToAnyPublisher()
    }
}

extension Request {
    var argsJSON: String {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: args, options: [.sortedKeys])
        return String(data: data, encoding: .utf8)!
    }
}
