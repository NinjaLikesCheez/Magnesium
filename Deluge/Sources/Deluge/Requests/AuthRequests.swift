public extension Request {
    /// Attempts to authenticate with the server.
    ///
    /// This is an `auth.login` RPC request.
    static var authenticate: Request<Void> {
        return .rpc(.init(
            method: "auth.login",
            authenticateIfNeeded: false,
            prepare: { request, client in
                var request = request
                request.params = [client.password]
                return request
            },
            transform: { response -> Result<Void, Client.Error> in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else {
                    return .failure(.unauthenticated)
                }

                return .success(())
            }
        ))
    }
}
