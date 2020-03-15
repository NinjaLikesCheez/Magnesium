public extension Request {
    /// Starts torrents with the given IDs and/or hashes.
    ///
    /// RPC Method: `torrent-start`
    ///
    /// - Parameter ids: The torrent IDs and/or hashes to start.
    static func start(ids: [Any]) -> Request<Void> {
        .init(method: "torrent-start", args: ["ids": ids])
    }

    /// Stops torrents with the given IDs and/or hashes.
    ///
    /// RPC Method: `torrent-stop`
    ///
    /// - Parameter ids: The torrent IDs and/or hashes to stop.
    static func stop(ids: [Any]) -> Request<Void> {
        .init(method: "torrent-stop", args: ["ids": ids])
    }

    /// Verifies the data for torrents with the given IDs and/or hashes.
    ///
    /// RPC Method: `torrent-verify`
    ///
    /// - Parameter ids: The torrent IDs and/or hashes to verify.
    static func verify(ids: [Any]) -> Request<Void> {
        .init(method: "torrent-verify", args: ["ids": ids])
    }

    /// Forces a reannounce for torrents with the given IDs and/or hashes.
    ///
    /// RPC Method: `torrent-reannounce`
    ///
    /// - Parameter ids: The torrent IDs and/or hashes to reannounce.
    static func reannounce(ids: [Any]) -> Request<Void> {
        .init(method: "torrent-reannounce", args: ["ids": ids])
    }
}
