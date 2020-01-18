//
//  TransmissionClient.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

enum TransmissionClientError: Error {
    case encoding(Error)
    case decoding(Error)
    case request(URLError)
    case statusCode(Int)
    case noSessionID
    case unauthenticated
    case unexpectedResponse
    case serverError(result: String?)
}

extension TransmissionClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .encoding(error):
            return error.localizedDescription
        case let .decoding(error):
            return error.localizedDescription
        case let .request(error):
            return error.localizedDescription
        case let .statusCode(statusCode):
            return "The server returned an unexpected status code (\(statusCode))."
        case .noSessionID:
            return "Unable to retrieve Session ID."
        case .unauthenticated:
            return "Unable to authenticate. Verify that your credentials are correct."
        case .unexpectedResponse:
            return "The server returned an unexpected response."
        case let .serverError(result: result):
            if let result = result {
                return "The server returned an error: \(result)"
            } else {
                return "The server returned an error."
            }
        }
    }
}

final class TransmissionClient {
    private enum Headers {
        static let sessionID = "X-Transmission-Session-Id"
    }

    private var sessionID: String?

    private lazy var session: URLSession = {
        URLSession.shared
    }()

    let baseURL: URL
    let username: String?
    let password: String?

    init(baseURL: URL, username: String?, password: String?) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
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

        if let username = username, let password = password {
            if let data = "\(username):\(password)".data(using: .utf8) {
                request.addValue("Basic \(data.base64EncodedString())", forHTTPHeaderField: "Authorization")
            }
        }

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
                    case 200 ..< 300:
                        break
                    case 401:
                        return Fail(error: .unauthenticated).eraseToAnyPublisher()
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

    func authenticate() -> AnyPublisher<Never, TransmissionClientError> {
        return request(method: "session-get", args: ["fields": ["version"]])
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func getTorrents() -> AnyPublisher<[TransmissionTorrent], TransmissionClientError> {
        let fields = [
            "id",
            "hashString",
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
