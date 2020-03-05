public extension Request {
    /// Attempts to authenticate with the server. This will produce a `Void` value if authenticated.
    ///
    /// This is an `auth.login` RPC request.
    static var authenticate: Request<Void> {
        return .init(
            method: "auth.login",
            params: [],
            authenticateIfNeeded: false,
            prepare: { request, client in
                var request = request
                request.params = [client.password]
                return request
            },
            transform: { response in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else { return .failure(.unauthenticated) }
                return .success(())
            }
        )
    }
}
