import Combine
import Foundation

/// An API client to interact with a Deluge server.
public final class Client {
    /// Errors that can occur during client operations.
    public enum Error: Swift.Error {
        /// An error occurred while encoding the request.
        case encoding(Swift.Error)
        /// An error occurred while decoding the response.
        case decoding(Swift.Error)
        /// A filesystem error occurred.
        case filesystem(Swift.Error)
        /// A request error occurred.
        case request(URLError)
        /// The provided authentication was not valid.
        case unauthenticated
        /// The server returned an unexpected response.
        case unexpectedResponse
        /// The server returned an error message.
        case serverError(message: String?)
    }

    private lazy var session: URLSession = {
        URLSession.shared
    }()

    /// The URL of the Deluge server.
    public let baseURL: URL
    /// The password to authentication with.
    public let password: String

    /// Creates a new `Client` with the given parameters.
    /// - Parameters:
    ///   - baseURL: The URL of the Deluge server.
    ///   - password: The password to authentication with.
    public init(baseURL: URL, password: String) {
        self.baseURL = baseURL
        self.password = password
    }

    private func request(
        method: String,
        params: [Any],
        authenticateIfNeeded: Bool = true
    ) -> AnyPublisher<[String: Any], Error> {
        let url = baseURL.appendingPathComponent("json")
        var request = URLRequest(url: url)
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

        return send(request: request, authenticateIfNeeded: authenticateIfNeeded) {
            return self.request(method: method, params: params, authenticateIfNeeded: false)
        }
    }

    private func send(
        request: URLRequest,
        authenticateIfNeeded: Bool,
        retry: @escaping () -> AnyPublisher<[String: Any], Error>
    ) -> AnyPublisher<[String: Any], Error> {
        return session.dataTaskPublisher(for: request)
            .mapError { .request($0) }
            .flatMap { data, response -> AnyPublisher<[String: Any], Error> in
                switch self.parse(data: data, response: response) {
                case let .success(response):
                    return Just(response)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case let .failure(error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .catch { error -> AnyPublisher<[String: Any], Error> in
                guard case .unauthenticated = error, authenticateIfNeeded else {
                    return Fail(error: error).eraseToAnyPublisher()
                }

                return self.authenticate()
                    .flatMap { _ -> AnyPublisher<[String: Any], Error> in
                        retry()
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func parse(data: Data, response: URLResponse) -> Result<[String: Any], Error> {
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

    /// Attempts to authenticate with the server.
    public func authenticate() -> AnyPublisher<Void, Error> {
        return request(method: "auth.login", params: [password], authenticateIfNeeded: false)
            .flatMap { response -> AnyPublisher<Void, Error> in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else {
                    return Fail(error: .unauthenticated).eraseToAnyPublisher()
                }

                return Just(()).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Fetches the list of torrents from the server.
    public func fetchTorrents() -> AnyPublisher<[Torrent], Error> {
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
            .flatMap { response -> AnyPublisher<[Torrent], Error> in
                guard let results = response["result"] as? [String: Any],
                    let torrents = results["torrents"] as? [String: [String: Any]]
                else {
                    return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
                }

                return Just(torrents.compactMap { Torrent(hash: $0.key, dictionary: $0.value) })
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Fetches the list labels from the server.
    public func fetchLabels() -> AnyPublisher<[String], Error> {
        return request(method: "label.get_labels", params: [])
            .flatMap { response -> AnyPublisher<[String], Error> in
                guard let result = response["result"] as? [String] else {
                    return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
                }

                return Just(result).setFailureType(to: Error.self).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func parseTorrentFileResponse(_ response: [String: Any]) -> Result<[TorrentFile], Error> {
        guard let results = response["result"] as? [String: Any],
            let contents = results["contents"] as? [String: [String: Any]]
        else {
            return .failure(.unexpectedResponse)
        }

        func parseDirectory(_ contents: [String: [String: Any]]) -> [TorrentFile] {
            var files = [TorrentFile]()
            for (name, node) in contents {
                guard let type = node["type"] as? String else {
                    continue
                }

                switch type {
                case "dir":
                    guard let child = node["contents"] as? [String: [String: Any]] else { break }
                    files.append(contentsOf: parseDirectory(child))
                case "file":
                    guard let file = TorrentFile(name: name, dictionary: node) else { break }
                    files.append(file)
                default:
                    break
                }
            }
            return files
        }

        return .success(parseDirectory(contents))
    }

    /// Fetches the files for a torrent.
    /// - Parameter hash: The hash of the torrent to request files for.
    public func fetchTorrentFiles(hash: String) -> AnyPublisher<[TorrentFile], Error> {
        return request(method: "web.get_torrent_files", params: [hash])
            .flatMap { response -> AnyPublisher<[TorrentFile], Error> in
                switch self.parseTorrentFileResponse(response) {
                case let .success(files):
                    return Just(files).setFailureType(to: Error.self).eraseToAnyPublisher()
                case let .failure(error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    /// Pauses torrents.
    /// - Parameter hashes: The hashes of the torrents to pause.
    public func pause(hashes: [String]) -> AnyPublisher<Void, Error> {
        return request(method: "core.pause_torrent", params: [hashes])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Resumes torrents.
    /// - Parameter hashes: The hashes of the torrents to resume.
    public func resume(hashes: [String]) -> AnyPublisher<Void, Error> {
        return request(method: "core.resume_torrent", params: [hashes])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Removes torrents from the server.
    /// - Parameters:
    ///   - hashes: The hashes of the torrents to remove.
    ///   - removeData: If the torrents' data should be removed.
    public func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Void, Error> {
        return request(method: "core.remove_torrents", params: [hashes, removeData])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Rechecks torrents.
    /// - Parameter hashes: The hashes of the torrents to recheck.
    public func recheck(hashes: [String]) -> AnyPublisher<Void, Error> {
        return request(method: "core.force_recheck", params: [hashes])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Adds a torrent using a link to a torrent file.
    /// - Parameter url: The torrent file link.
    public func add(url: URL) -> AnyPublisher<Void, Error> {
        return request(method: "core.add_torrent_url", params: [url.absoluteString, [String: Any]()])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Adds a torrent using a magnet link.
    /// - Parameter magnetURL: The magnet link to add.
    public func add(magnetURL: URL) -> AnyPublisher<Void, Error> {
        return request(method: "core.add_torrent_magnet", params: [magnetURL.absoluteString, [String: Any]()])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Adds a torrent using a local file URL.
    /// - Parameter fileURL: The URL of the file to add.
    public func add(fileURL: URL) -> AnyPublisher<Void, Error> {
        return upload(fileURL: fileURL)
            .flatMap { response -> AnyPublisher<[String: Any], Error> in
                guard let path = (response["files"] as? [String])?.first else {
                    return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
                }

                return self.request(method: "web.add_torrents", params: [[["path": path, "options": [String: Any]()]]])
            }
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func upload(fileURL: URL, authenticateIfNeeded: Bool = true) -> AnyPublisher<[String: Any], Error> {
        let url = baseURL.appendingPathComponent("upload")
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        switch multipartBody(fileURL: fileURL, boundary: boundary) {
        case let .success(data):
            request.httpBody = data
        case let .failure(error):
            return Fail(error: error).eraseToAnyPublisher()
        }

        return send(request: request, authenticateIfNeeded: authenticateIfNeeded) {
            return self.upload(fileURL: fileURL, authenticateIfNeeded: false)
        }
    }

    private func multipartBody(fileURL: URL, boundary: String) -> Result<Data, Error> {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            return .failure(.filesystem(error))
        }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
            .data(using: .utf8)!)
        body.append("Content-Type: application/x-bittorrent\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--".data(using: .utf8)!)
        return .success(body)
    }
}

extension Client.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .encoding(error):
            return error.localizedDescription
        case let .decoding(error):
            return error.localizedDescription
        case let .filesystem(error):
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
        }
    }
}
