//
//  TransmissionClient.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

enum TransmissionClientError: Swift.Error {
    case encoding(Swift.Error)
    case decoding(Swift.Error)
    case request(URLError)
    case statusCode(Int)
    case noSessionID
    case unauthenticated
    case unexpectedResponse
    case serverError(result: String?)
}

final class TransmissionClient {
    private enum Headers {
        static let sessionID = "X-Transmission-Session-Id"
    }

    struct Authentication {
        var username: String
        var password: String
    }

    private var sessionID: String?

    private lazy var session: URLSession = {
        URLSession.shared
    }()

    var baseURL: URL
    var authentication: Authentication?

    init(baseURL: URL, authentication: Authentication?) {
        self.baseURL = baseURL
        self.authentication = authentication
    }

    private func request(
        method: String,
        args: [String: Any],
        handleSessionID: Bool = true
    ) -> AnyPublisher<[String: Any], TransmissionClientError> {
        let rpcUrl = baseURL.appendingPathComponent("transmission").appendingPathComponent("rpc")

        var request = URLRequest(url: rpcUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let sessionID = sessionID {
            request.addValue(sessionID, forHTTPHeaderField: Headers.sessionID)
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "method": method,
                "arguments": args,
            ], options: [])
        } catch {
            return Fail(error: .encoding(error)).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .mapError { .request($0) }
            .flatMap { data, response -> AnyPublisher<[String: Any], TransmissionClientError> in
                if let response = response as? HTTPURLResponse {
                    switch response.statusCode {
                    case 200..<300:
                        break
                    case 409:
                        guard handleSessionID,
                            let sessionID = response.allHeaderFields[Headers.sessionID] as? String
                        else {
                            return Fail(error: .noSessionID).eraseToAnyPublisher()
                        }

                        self.sessionID = sessionID
                        return self.request(method: method, args: args, handleSessionID: false)
                    default:
                        return Fail(error: .statusCode(response.statusCode)).eraseToAnyPublisher()
                    }
                }

                switch self.parse(data: data, response: response) {
                case let .success(response):
                    return Just(response)
                        .setFailureType(to: TransmissionClientError.self)
                        .eraseToAnyPublisher()
                case let .failure(error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    private func parse(data: Data, response: URLResponse) -> Result<[String: Any], TransmissionClientError> {
        let dict: [String: Any]

        do {
            guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return .failure(.unexpectedResponse)
            }

            dict = object
        } catch {
            return .failure(.decoding(error))
        }

        guard let result = dict["result"] as? String else {
            return .failure(.unexpectedResponse)
        }

        switch result {
        case "success":
            return .success(dict)
        default:
            return .failure(.serverError(result: result))
        }
    }

    func getTorrents() -> AnyPublisher<[TransmissionTorrent], TransmissionClientError> {
        let fields = [
            "id",
            "name",
            "status",
            "addedDate",
            "rateDownload",
            "rateUpload",
            "eta",
            "percentDone",
            "downloadedEver",
            "uploadedEver",
            "totalSize",
            "trackerStats",
        ]

        return request(method: "torrent-get", args: ["fields": fields])
            .flatMap { response -> AnyPublisher<[TransmissionTorrent], TransmissionClientError> in
                guard let arguments = response["arguments"] as? [String: Any],
                    let torrents = arguments["torrents"] as? [[String: Any]]
                else {
                    return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
                }

                return Just(torrents.compactMap { TransmissionTorrent(dictionary: $0) })
                    .setFailureType(to: TransmissionClientError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
