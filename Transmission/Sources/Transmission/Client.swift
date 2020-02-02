import Combine
import Foundation

/// An API client to interact with a Transmission server.
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
        /// The server returned an unexpected status code.
        case statusCode(Int)
        /// Unable to obtain a Session ID.
        case noSessionID
        /// The provided authentication was not valid.
        case unauthenticated
        /// The server returned an unexpected response.
        case unexpectedResponse
        /// The server returned an error result.
        case serverError(result: String?)
    }

    private enum Headers {
        static let sessionID = "X-Transmission-Session-Id"
    }

    private var sessionID: String?

    private lazy var session: URLSession = {
        URLSession.shared
    }()

    /// The URL of the Transmission server.
    public let baseURL: URL
    /// The username to authenticate with.
    public let username: String?
    /// The password to authenticate with.
    public let password: String?

    /// Creates a new `Client` with the given parameters.
    /// - Parameters:
    ///   - baseURL: The URL of the Transmission server.
    ///   - username: The username to authenticate with.
    ///   - password: The password to authenticate with.
    public init(baseURL: URL, username: String?, password: String?) {
        self.baseURL = baseURL
        self.username = username
        self.password = password
    }

    private func request(
        method: String,
        args: [String: Any],
        handleSessionID: Bool = true
    ) -> AnyPublisher<[String: Any], Error> {
        let url = baseURL.appendingPathComponent("transmission").appendingPathComponent("rpc")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if username != nil || password != nil {
            let username = self.username ?? ""
            let password = self.password ?? ""
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
            .flatMap { data, response -> AnyPublisher<[String: Any], Error> in
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

                switch Client.parse(data: data, response: response) {
                case let .success(response):
                    return Just(response)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                case let .failure(error):
                    return Fail(error: error).eraseToAnyPublisher()
                }
            }
            .eraseToAnyPublisher()
    }

    private static func parse(data: Data, response: URLResponse) -> Result<[String: Any], Error> {
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

    /// Attempts to authenticate with the server.
    public func authenticate() -> AnyPublisher<Void, Error> {
        return request(method: "session-get", args: ["fields": ["version"]])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Fetches the list of torrents from the server.
    public func fetchTorrents() -> AnyPublisher<[Torrent], Error> {
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
            .flatMap { response -> AnyPublisher<[Torrent], Error> in
                guard let arguments = response["arguments"] as? [String: Any],
                    let torrents = arguments["torrents"] as? [[String: Any]]
                else {
                    return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
                }

                return Just(torrents.compactMap { Torrent(dictionary: $0) })
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Adds a torrent using a link to a torrent file or a magnet link.
    /// - Parameter url: A torrent link or magnet link.
    public func add(url: URL) -> AnyPublisher<Void, Error> {
        return request(method: "torrent-add", args: ["filename": url.absoluteString])
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    /// Adds a torrent using a local file URL.
    /// - Parameter fileURL: The URL of the file to add.
    public func add(fileURL: URL) -> AnyPublisher<Void, Error> {
        do {
            let data = try Data(contentsOf: fileURL)
            return request(method: "torrent-add", args: ["metainfo": data.base64EncodedString()])
                .map { _ in () }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: .filesystem(error)).eraseToAnyPublisher()
        }
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
