import Combine
import Foundation

/// A Deluge JSON-RPC API client.
public final class Client {
    /// Errors that can occur during client operations.
    public enum Error: Swift.Error {
        /// An error occurred while encoding the request.
        case encoding(Swift.Error)
        /// An error occurred while decoding the response.
        case decoding(Swift.Error)
        /// A request error occurred.
        case request(URLError)
        /// The provided authentication was not valid.
        case unauthenticated
        /// The server returned an unexpected response.
        case unexpectedResponse
        /// The server returned an error message.
        case serverError(message: String?)
    }

    /// The `URLSession` to use for requests.
    private lazy var session: URLSession = {
        URLSession.shared
    }()

    /// The URL of the Deluge server.
    let baseURL: URL
    /// The password used for authentication.
    let password: String

    /// Creates a `Client` with the given parameters.
    /// - Parameters:
    ///   - baseURL: The URL of the Deluge server.
    ///   - password: The password used for authentication.
    public init(baseURL: URL, password: String) {
        self.baseURL = baseURL
        self.password = password
    }

    /// Sends a `Request` to the server.
    /// - Parameter request: The request to be sent to the server.
    /// - Returns: A publisher that emits a value when the request completes.
    public func request<Value>(_ request: Request<Value>) -> AnyPublisher<Value, Error> {
        self.request(urlRequest(from: request.prepare(request, self)), transform: request.transform)
    }

    /// Attempts to send a `Result` containing `URLRequest` to the server. If the `Result` contains an error then the
    /// request will not be performed and the returned publisher will fail immediately.
    /// - Parameters:
    ///   - request: A `Result` containing the request to be sent to the server.
    ///   - transform: Transforms the server response in to a new representation.
    /// - Returns: A publisher that emits a value when the request completes.
    private func request<Value>(
        _ request: Result<URLRequest, Error>,
        transform: @escaping ([String: Any]) -> Result<Value, Error>
    ) -> AnyPublisher<Value, Error> {
        request.publisher
            .map { ($0, true) }
            .flatMap(send(request:authenticateIfNeeded:))
            .flatMap { transform($0).publisher.eraseToAnyPublisher() }
            .eraseToAnyPublisher()
    }

    /// Creates a `URLRequest` from a `Request`.
    /// - Parameters:
    ///   - request: The request definition to be converted in to a `URLRequest`.
    /// - Returns: A `Result` containing either the created `URLRequest` or an `Error` if the request body (method +
    /// parameters) were unable to be serialized to JSON.
    private func urlRequest<Value>(from request: Request<Value>) -> Result<URLRequest, Error> {
        let url = baseURL.appendingPathComponent("json")
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: [
                "id": 1,
                "method": request.method,
                "params": request.params,
            ], options: [])
        } catch {
            return .failure(Error.encoding(error))
        }

        return .success(urlRequest)
    }

    /// Sends a `URLRequest` performing optional authentication.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` to be sent.
    ///   - authenticateIfNeeded: Whether authentication should be attempted if the server responds that the client is
    ///   unauthenticated.
    /// - Returns: A publisher that emits the decoded server response.
    private func send(request: URLRequest, authenticateIfNeeded: Bool) -> AnyPublisher<[String: Any], Error> {
        let retryIfNeeded = { (error: Error) -> AnyPublisher<[String: Any], Error> in
            guard case .unauthenticated = error, authenticateIfNeeded else {
                return Fail(error: error).eraseToAnyPublisher()
            }

            return self.request(.authenticate)
                .flatMap { self.send(request: request, authenticateIfNeeded: false) }
                .eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: request)
            .mapError { .request($0) }
            .flatMap(decode(data:response:))
            .catch(retryIfNeeded)
            .eraseToAnyPublisher()
    }

    /// Attempts to decode a server response in to a dictionary.
    /// - Parameters:
    ///   - data: The data returned from the server.
    ///   - response: The `URLResponse` describing the server response.
    /// - Returns: A publisher that emits the decoded dictionary.
    private func decode(data: Data, response: URLResponse) -> AnyPublisher<[String: Any], Error> {
        let dict: [String: Any]

        do {
            guard let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
            }

            dict = object
        } catch {
            return Fail(error: .decoding(error)).eraseToAnyPublisher()
        }

        if let error = dict["error"] as? [String: Any] {
            if let code = error["code"] as? Int, code == 1 {
                return Fail(error: .unauthenticated).eraseToAnyPublisher()
            }

            return Fail(error: .serverError(message: error["message"] as? String)).eraseToAnyPublisher()
        }

        return Just(dict).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
