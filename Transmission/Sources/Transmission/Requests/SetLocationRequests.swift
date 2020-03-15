public extension Request {
    /// Moves the storage for torrents with the given IDs and/or hashes.
    ///
    /// RPC Method: `torrent-set-location`
    ///
    /// - Parameters:
    ///   - ids: The torrent IDs and/or hashes whose storage should be moved.
    ///   - path: The new path where the torrents' data should be stored.
    static func move(ids: [Any], path: String) -> Request<Void> {
        .init(method: "torrent-set-location", args: ["ids": ids, "location": path, "move": true])
    }
}
