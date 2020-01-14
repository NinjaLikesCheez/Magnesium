//
//  DelugeClient.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-07.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation

protocol DelugeClient {
    func authenticate() -> AnyPublisher<Never, DelugeClientError>
    func getTorrents() -> AnyPublisher<[DelugeTorrent], DelugeClientError>
    func getLabels() -> AnyPublisher<[String], DelugeClientError>
    func getTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeClientError>
    func pause(hashes: [String]) -> AnyPublisher<Never, DelugeClientError>
    func resume(hashes: [String]) -> AnyPublisher<Never, DelugeClientError>
    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Never, DelugeClientError>
    func recheck(hashes: [String]) -> AnyPublisher<Never, DelugeClientError>
}

extension DelugeClient {
    func pause(hash: String) -> AnyPublisher<Never, DelugeClientError> {
        return pause(hashes: [hash])
    }

    func resume(hash: String) -> AnyPublisher<Never, DelugeClientError> {
        return resume(hashes: [hash])
    }

    func remove(hash: String, removeData: Bool) -> AnyPublisher<Never, DelugeClientError> {
        return remove(hashes: [hash], removeData: removeData)
    }

    func recheck(hash: String) -> AnyPublisher<Never, DelugeClientError> {
        return recheck(hashes: [hash])
    }
}

enum DelugeClientError: Swift.Error {
    case encoding(Swift.Error)
    case decoding(Swift.Error)
    case request(URLError)
    case unauthenticated
    case unexpectedResponse
    case serverError(message: String?)
    case ensureWebInterfaceConnectivity
    case noLabelPlugin
}

final class DefaultDelugeClient: DelugeClient {
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
    ) -> AnyPublisher<[String: Any], DelugeClientError> {
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
            .mapError { DelugeClientError.request($0) }
            .flatMap { data, response -> AnyPublisher<[String: Any], DelugeClientError> in
                do {
                    return try Just(self.parse(data: data, response: response))
                        .setFailureType(to: DelugeClientError.self)
                        .eraseToAnyPublisher()
                } catch {
                    return Fail(error: DelugeClientError.decoding(error)).eraseToAnyPublisher()
                }
            }
            .catch { error -> AnyPublisher<[String: Any], DelugeClientError> in
                guard authenticateIfNeeded else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return self.authenticate()
                    .flatMap { _ -> AnyPublisher<[String: Any], DelugeClientError> in
                        self.request(method: method, params: params, authenticateIfNeeded: false)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func parse(data: Data, response: URLResponse) throws -> [String: Any] {
        guard let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw DelugeClientError.unexpectedResponse
        }

        if let error = dict["error"] as? [String: Any] {
            if let code = error["code"] as? Int, code == 1 {
                throw DelugeClientError.unauthenticated
            }

            throw DelugeClientError.serverError(message: error["message"] as? String)
        }

        return dict
    }

    func authenticate() -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "auth.login", params: [password], authenticateIfNeeded: false)
            .flatMap { response -> AnyPublisher<Never, DelugeClientError> in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else {
                    return Fail(error: DelugeClientError.unauthenticated).eraseToAnyPublisher()
                }

                return Empty(completeImmediately: true).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getTorrents() -> AnyPublisher<[DelugeTorrent], DelugeClientError> {
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
            .flatMap { response -> AnyPublisher<[DelugeTorrent], DelugeClientError> in
                guard let results = response["result"] as? [String: Any],
                    let torrents = results["torrents"] as? [String: [String: Any]]
                else {
                    return Fail(error: DelugeClientError.ensureWebInterfaceConnectivity).eraseToAnyPublisher()
                }

                return Just(torrents.compactMap { DelugeTorrent(hash: $0.key, dictionary: $0.value) })
                    .setFailureType(to: DelugeClientError.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func getLabels() -> AnyPublisher<[String], DelugeClientError> {
        return request(method: "label.get_labels", params: [])
            .flatMap { value -> AnyPublisher<[String], DelugeClientError> in
                guard let result = value["result"] as? [String] else {
                    return Fail(error: DelugeClientError.unexpectedResponse).eraseToAnyPublisher()
                }

                return Just(result).setFailureType(to: DelugeClientError.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func parseTorrentFileResponse(_ response: [String: Any]) -> Result<[DelugeTorrentFile], DelugeClientError> {
        guard let results = response["result"] as? [String: Any],
            let contents = results["contents"] as? [String: [String: Any]]
        else {
            return .failure(.unexpectedResponse)
        }

        func parseDirectory(_ contents: [String: [String: Any]]) -> [DelugeTorrentFile] {
            var files = [DelugeTorrentFile]()
            for (name, node) in contents {
                guard let type = node["type"] as? String else {
                    continue
                }

                switch type {
                case "dir":
                    guard let child = node["contents"] as? [String: [String: Any]] else { break }
                    files.append(contentsOf: parseDirectory(child))
                case "file":
                    guard let file = DelugeTorrentFile(name: name, dictionary: node) else { break }
                    files.append(file)
                default:
                    break
                }
            }
            return files
        }

        return .success(parseDirectory(contents))
    }

    func getTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeClientError> {
        return request(method: "web.get_torrent_files", params: [hash])
            .flatMap { response -> AnyPublisher<[DelugeTorrentFile], DelugeClientError> in
                switch self.parseTorrentFileResponse(response) {
                case let .success(files):
                    return Just(files).setFailureType(to: DelugeClientError.self).eraseToAnyPublisher()
                case let .failure(error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    func pause(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.pause_torrent", params: hashes)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.resume_torrent", params: hashes)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.remove_torrents", params: [hashes, removeData])
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.force_recheck", params: hashes)
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}
