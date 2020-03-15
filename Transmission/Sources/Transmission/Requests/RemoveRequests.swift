public extension Request {
    /// Removes torrents with the given IDs and/or hashes.
    ///
    /// RPC Method: `torrent-remove`
    ///
    /// - Parameters:
    ///   - ids: The torrent IDs and/or hashes to remove.
    ///   - removeData: Whether the torrents' data should be removed.
    static func remove(ids: [Any], removeData: Bool) -> Request<Void> {
        .init(method: "torrent-remove", args: ["ids": ids, "delete-local-data": removeData])
    }
}
