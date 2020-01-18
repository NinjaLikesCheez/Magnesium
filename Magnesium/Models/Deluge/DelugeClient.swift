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

enum DelugeClientError: Error {
    case encoding(Error)
    case decoding(Error)
    case request(Error)
    case unauthenticated
    case unexpectedResponse
    case serverError(message: String?)
    case ensureWebInterfaceConnectivity
}

extension DelugeClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .encoding(error):
            return error.localizedDescription
        case let .decoding(error):
            return error.localizedDescription
        case let .request(error):
            return error.localizedDescription
        case .unauthenticated:
            return "Unable to authenticate. Verify that your credentials are correct."
        case .unexpectedResponse:
            return "The server returned an unexpected response."
        case let .serverError(message: message):
            if let message = message {
                return "The server returned an error: \(message)"
            } else {
                return "The server returned an error."
            }
        case .ensureWebInterfaceConnectivity:
            return "Unable to retreive torrents. Ensure the web interface is connected to the daemon."
        }
    }
}

final class DefaultDelugeClient: DelugeClient {
    private lazy var session: URLSession = {
        URLSession.shared
    }()

    var baseURL: URL
    var password: String

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
                switch self.parse(data: data, response: response) {
                case let .success(response):
                    return Just(response)
                        .setFailureType(to: DelugeClientError.self)
                        .eraseToAnyPublisher()
                case let .failure(error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .catch { error -> AnyPublisher<[String: Any], DelugeClientError> in
                guard case .unauthenticated = error, authenticateIfNeeded else {
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

    private func parse(data: Data, response: URLResponse) -> Result<[String: Any], DelugeClientError> {
        let dict: [String: Any]

        do {
            guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return .failure(.unexpectedResponse)
            }

            dict = object
        } catch {
            return .failure(.decoding(error))
        }

        if let error = dict["error"] as? [String: Any] {
            if let code = error["code"] as? Int, code == 1 {
                return .failure(.unauthenticated)
            }

            return .failure(.serverError(message: error["message"] as? String))
        }

        return .success(dict)
    }

    func authenticate() -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "auth.login", params: [password], authenticateIfNeeded: false)
            .flatMap { response -> AnyPublisher<Never, DelugeClientError> in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else {
                    return Fail(error: .unauthenticated).eraseToAnyPublisher()
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
                    return Fail(error: .ensureWebInterfaceConnectivity).eraseToAnyPublisher()
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
                    return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
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
        return request(method: "core.pause_torrent", params: [hashes])
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func resume(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.resume_torrent", params: [hashes])
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.remove_torrents", params: [hashes, removeData])
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func recheck(hashes: [String]) -> AnyPublisher<Never, DelugeClientError> {
        return request(method: "core.force_recheck", params: [hashes])
            .ignoreOutput()
            .eraseToAnyPublisher()
    }
}
