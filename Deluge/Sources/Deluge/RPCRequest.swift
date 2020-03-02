import Combine
import Foundation

/// A definition for a Deluge RPC request.
public struct RPCRequest<Value> {
    /// The RPC method.
    public var method: String
    /// The parameters passed with the request.
    public var params: [Any]
    /// Whether authentication should be attempted if the server indicates that the client is unauthenticated.
    public var authenticateIfNeeded: Bool
    /// Creates a new version of the request using information from the `Client`.
    public var prepare: (Self, Client) -> Self
    /// Transforms the server response in to a new representation.
    public var transform: ([String: Any]) -> Transform<Value>

    /// Creates an `RPCRequest` with the given parameters.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - authenticateIfNeeded: Whether authentication should be attempted if the server indicates that the
    ///    client is unauthenticated.
    ///   - prepare: Creates a new version of the request using information from the `Client`.
    ///   - transform: Transforms the server response in to a new representation.
    public init(
        method: String,
        params: [Any] = [],
        authenticateIfNeeded: Bool = true,
        prepare: @escaping (Self, Client) -> Self = { request, _ in request },
        transform: @escaping ([String: Any]) -> Transform<Value>
    ) {
        self.method = method
        self.params = params
        self.authenticateIfNeeded = authenticateIfNeeded
        self.prepare = prepare
        self.transform = transform
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
    init(
        method: String,
        params: [Any] = [],
        authenticateIfNeeded: Bool = true,
        prepare: @escaping (Self, Client) -> Self = { request, _ in request },
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
}

public extension RPCRequest where Value == Void {
    /// A convenience initializer for `Void` transforms. This provides a default transform implementation that simply
    /// returns `Void`.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - authenticateIfNeeded: Whether authentication should be attempted if the server indicates that the
    ///    client is unauthenticated.
    ///   - prepare: Creates a new version of the request using information from the `Client`.
    init(
        method: String,
        params: [Any] = [],
        authenticateIfNeeded: Bool = true,
        prepare: @escaping (Self, Client) -> Self = { request, _ in request }
    ) {
        self.init(
            method: method,
            params: params,
            authenticateIfNeeded: authenticateIfNeeded,
            prepare: prepare,
            transform: { _ in .success(()) }
        )
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
            transform: { (value: [String: Any]) -> Transform<NewValue> in
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
