import Combine
import Foundation

/// A definition for a Deluge RPC request.
///
/// An `RPCRequest` makes an HTTP POST request to `/json`.
/// You can use this type of request to interact with the Deluge JSON-RPC API.
public struct RPCRequest<Value> {
    /// The RPC method.
    public var method: String
    /// The parameters passed with the request.
    public var params: [Any]
    /// Transforms the server response in to a new representation.
    public var transform: ([String: Any]) -> Transformed<Value>
    /// Whether authentication should be attempted if the server indicates that the client is unauthenticated.
    internal var authenticateIfNeeded: Bool
    /// Creates a new version of the request using information from the `Client`.
    internal var prepare: (Self, Client) -> Self

    /// Creates an `RPCRequest` with the given parameters.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - authenticateIfNeeded: Whether authentication should be attempted if the server indicates that the
    ///    client is unauthenticated.
    ///   - prepare: Creates a new version of the request using information from the `Client`.
    ///   - transform: Transforms the server response in to a new representation.
    internal init(
        method: String,
        params: [Any],
        authenticateIfNeeded: Bool = true,
        prepare: @escaping (Self, Client) -> Self,
        transform: @escaping ([String: Any]) -> Transformed<Value>
    ) {
        self.method = method
        self.params = params
        self.authenticateIfNeeded = authenticateIfNeeded
        self.prepare = prepare
        self.transform = transform
    }

    /// Creates an `RPCRequest` with the given parameters.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - transform: Transforms the server response in to a new representation.
    public init(method: String, params: [Any], transform: @escaping ([String: Any]) -> Transformed<Value>) {
        self.init(method: method, params: params, prepare: { request, _ in request }, transform: transform)
    }
}

public extension RPCRequest {
    /// A convenience initializer for `Result` transforms.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - authenticateIfNeeded: Whether authentication should be attempted if the server indicates that the
    ///    client is unauthenticated.
    ///   - prepare: Creates a new version of the request using information from the `Client`.
    ///   - transform: Transforms the server response in to a new representation.
    internal init(
        method: String,
        params: [Any],
        authenticateIfNeeded: Bool = true,
        prepare: @escaping (Self, Client) -> Self,
        transform: @escaping ([String: Any]) -> Result<Value, Client.Error>
    ) {
        self.init(
            method: method,
            params: params,
            authenticateIfNeeded: authenticateIfNeeded,
            prepare: prepare,
            transform: { .result(transform($0)) }
        )
    }

    /// A convenience initializer for `Result` transforms.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - transform: Transforms the server response in to a new representation.
    init(method: String, params: [Any], transform: @escaping ([String: Any]) -> Result<Value, Client.Error>) {
        self.init(method: method, params: params, transform: { .result(transform($0)) })
    }
}

public extension RPCRequest where Value == Void {
    /// A convenience initializer for `Void` transforms. This provides a default transform implementation that simply
    /// returns `Void`.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    init(method: String, params: [Any]) {
        self.init(method: method, params: params, transform: { _ in .success(()) })
    }
}

public extension RPCRequest {
    /// Creates a new request by mapping the `Value` of the request in to a new representation.
    /// - Parameter transform: Transforms the value in to a new representation.
    /// - Returns: The newly created request.
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> RPCRequest<NewValue> {
        let original = self
        return RPCRequest<NewValue>(
            method: method,
            params: params,
            authenticateIfNeeded: authenticateIfNeeded,
            prepare: { request, client in
                let prepared = original.prepare(original, client)
                var request = request
                request.params = prepared.params
                return request
            },
            transform: { (value: [String: Any]) -> Transformed<NewValue> in
                switch original.transform(value) {
                case let .result(result):
                    return .result(result.map(transform))
                case let .request(request):
                    return .request(request.map(transform))
                }
            }
        )
    }
}
