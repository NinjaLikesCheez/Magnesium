//
//  DelugeClient.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

final class DelugeClient {
    enum Error: Swift.Error {
        case encoding(Swift.Error)
        case decoding(Swift.Error)
        case request(URLError)
        case unauthenticated
        case badResponseBody
        case serverError(message: String?)
        case ensureWebInterfaceConnectivity
    }

    private lazy var session: URLSession = {
        URLSession.shared
    }()

    let baseURL: URL
    let password: String

    init(baseURL: URL, password: String) {
        self.baseURL = baseURL
        self.password = password
    }

    private func request(
        method: String,
        params: [Any],
        authenticateIfNeeded: Bool = true
    ) -> AnyPublisher<[String: Any], Error> {
        let rpcUrl = baseURL.appendingPathComponent("json")

        var request = URLRequest(url: rpcUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: [
                "id": 1,
                "method": method,
                "params": params,
            ], options: [])
        } catch {
            return Fail(error: .encoding(error)).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .mapError { Error.request($0) }
            .flatMap { args -> AnyPublisher<[String: Any], Error> in
                let (data, response) = args
                do {
                    return try Just(self.parse(data: data, response: response))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: Error.decoding(error)).eraseToAnyPublisher()
                }
            }
            .catch { error -> AnyPublisher<[String: Any], Error> in
                guard authenticateIfNeeded else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return self.authenticate()
                    .flatMap { _ -> AnyPublisher<[String: Any], Error> in
                        self.request(method: method, params: params, authenticateIfNeeded: false)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func parse(data: Data, response: URLResponse) throws -> [String: Any] {
        guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.badResponseBody
        }

        if let error = dict["error"] as? [String: Any] {
            if let code = error["code"] as? Int, code == 1 {
                throw Error.unauthenticated
            }

            throw Error.serverError(message: error["message"] as? String)
        }

        return dict
    }

    func authenticate() -> AnyPublisher<Void, Error> {
        return request(method: "auth.login", params: [password], authenticateIfNeeded: false)
            .flatMap { response -> AnyPublisher<Void, Error> in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else {
                    return Fail(error: Error.unauthenticated).eraseToAnyPublisher()
                }

                return Just(())
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func torrents() -> AnyPublisher<[DelugeTorrent], Error> {
        let keys = [
            "name",
            "state",
            "time_added",
            "download_payload_rate",
            "upload_payload_rate",
            "eta",
            "progress",
            "total_done",
            "total_uploaded",
            "total_size",
            "num_seeds",
            "total_seeds",
            "num_peers",
            "total_peers",
            "trackers",
            "label",
        ]

        return request(method: "web.update_ui", params: [keys, []])
            .flatMap { response -> AnyPublisher<[DelugeTorrent], Error> in
                guard let results = response["result"] as? [String: Any],
                    let torrents = results["torrents"] as? [String: [String: Any]]
                else {
                    return Fail(error: Error.ensureWebInterfaceConnectivity).eraseToAnyPublisher()
                }

                return Just(torrents.compactMap { DelugeTorrent(hash: $0.key, dictionary: $0.value) })
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
