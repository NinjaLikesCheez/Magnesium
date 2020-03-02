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
    enum MockResult {
        case rpc(method: String, response: AnyPublisher<Any, Client.Error>)
        case upload(fileURL: URL, response: AnyPublisher<Any, Client.Error>)
    }

    private(set) var requestCallCount = 0
    private(set) var requestParamRequest = [Request<Any>]()
    var results = [MockResult]()
    func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, Client.Error> {
        requestCallCount += 1
        requestParamRequest.append(request.map { $0 as Any })

        let response: AnyPublisher<Value, Client.Error>?
        switch request {
        case let .rpc(request):
            response = results.compactMap {
                guard case let .rpc(method, response) = $0, method == request.method else { return nil }
                return response.map { $0 as! Value }.eraseToAnyPublisher() // swiftlint:disable:this force_cast
            }.first
        case let .upload(request):
            response = results.compactMap {
                guard case let .upload(fileURL, response) = $0, fileURL == request.fileURL else { return nil }
                return response.map { $0 as! Value }.eraseToAnyPublisher() // swiftlint:disable:this force_cast
            }.first
        }

        return response ?? Fail(error: .unexpectedResponse).eraseToAnyPublisher()
    }
}

extension Request {
    var method: String {
        switch self {
        case let .rpc(request):
            return request.method
        case .upload:
            return ""
        }
    }

    var params: [Any] {
        switch self {
        case let .rpc(request):
            return request.params
        case .upload:
            return []
        }
    }

    var paramsJSON: String {
        switch self {
        case let .rpc(request):
            // swiftlint:disable:next force_try
            let data = try! JSONSerialization.data(withJSONObject: request.params, options: [])
            return String(data: data, encoding: .utf8)!
        case .upload:
            return ""
        }
    }
}
