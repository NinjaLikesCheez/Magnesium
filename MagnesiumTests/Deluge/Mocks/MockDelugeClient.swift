//
//  MockDelugeClient.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-21.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Deluge
import Foundation
@testable import Magnesium

final class MockDelugeClient: DelugeClient {
    private(set) var requestCallCount = 0
    private(set) var requestParamRequest = [Request<Any>]()
    var results = [(method: String, result: AnyPublisher<Any, Client.Error>)]()
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, Client.Error> {
        requestCallCount += 1
        requestParamRequest.append(request.map { $0 as Any })
        let response = results.compactMap { result -> AnyPublisher<Value, Client.Error>? in
            guard result.method == request.method else { return nil }
            return result.result.map { $0 as! Value }.eraseToAnyPublisher() // swiftlint:disable:this force_cast
        }.first
        return response ?? Fail(error: .unexpectedResponse).eraseToAnyPublisher()
    }
}

extension Request {
    var paramsJSON: String {
        // swiftlint:disable:next force_try
        let data = try! JSONSerialization.data(withJSONObject: params, options: [])
        return String(data: data, encoding: .utf8)!
    }
}
