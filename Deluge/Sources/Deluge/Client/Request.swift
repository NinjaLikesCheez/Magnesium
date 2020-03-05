import Combine
import Foundation

/// A definition for a Deluge JSON-RPC request.
public struct Request<Value> {
    /// The RPC method.
    public var method: String
    /// The parameters passed with the request.
    public var params: [Any]
    /// Transforms the server response in to a new representation.
    public var transform: ([String: Any]) -> Result<Value, Client.Error>
    /// Whether authentication should be attempted if the server indicates that the client is unauthenticated.
    internal var authenticateIfNeeded: Bool
    /// Creates a new version of the request using information from the `Client`.
    internal var prepare: (Self, Client) -> Self

    /// Creates a `Request` with the given parameters.
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
        self.method = method
        self.params = params
        self.authenticateIfNeeded = authenticateIfNeeded
        self.prepare = prepare
        self.transform = transform
    }

    /// Creates a `Request` with the given parameters.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    ///   - transform: Transforms the server response in to a new representation.
    public init(method: String, params: [Any], transform: @escaping ([String: Any]) -> Result<Value, Client.Error>) {
        self.init(method: method, params: params, prepare: { request, _ in request }, transform: transform)
    }
}

public extension Request where Value == Void {
    /// A convenience initializer for `Void` transforms. This provides a default transform implementation that simply
    /// returns a `Void` value.
    /// - Parameters:
    ///   - method: The RPC method.
    ///   - params: The parameters passed with the request.
    init(method: String, params: [Any]) {
        self.init(method: method, params: params, transform: { _ in .success(()) })
    }
}

public extension Request {
    /// Creates a new request by mapping the `Value` of the request in to a new representation.
    /// - Parameter transform: Transforms the value in to a new representation.
    /// - Returns: The newly created request.
    func map<NewValue>(_ transform: @escaping (Value) -> NewValue) -> Request<NewValue> {
        let original = self
        return Request<NewValue>(
            method: method,
            params: params,
            authenticateIfNeeded: authenticateIfNeeded,
            prepare: { request, client in
                let prepared = original.prepare(original, client)
                var request = request
                request.params = prepared.params
                return request
            },
            transform: { original.transform($0).map(transform) }
        )
    }
}
