public extension Request {
    /// Resumes torrents with the given hashes.
    ///
    /// This is a `core.resume_torrent` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to resume.
    static func resume(hashes: [String]) -> Request<Void> {
        .rpc(.init(method: "core.resume_torrent", params: [hashes]))
    }

    /// Pauses torrents with the given hashes.
    ///
    /// This is a `core.pause_torrent` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to pause.
    static func pause(hashes: [String]) -> Request<Void> {
        .rpc(.init(method: "core.pause_torrent", params: [hashes]))
    }

    /// Removes torrents with the given hashes.
    ///
    /// This is a `core.remove_torrents` RPC request.
    ///
    /// - Parameters:
    ///   - hashes: The torrent hashes to remove.
    ///   - removeData: Whether the torrents' data should be removed.
    static func remove(hashes: [String], removeData: Bool) -> Request<Void> {
        .rpc(.init(method: "core.remove_torrents", params: [hashes, removeData]))
    }

    /// Rechecks torrents with the given hashes.
    ///
    /// This is a `core.force_recheck` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to recheck.
    static func recheck(hashes: [String]) -> Request<Void> {
        .rpc(.init(method: "core.force_recheck", params: [hashes]))
    }

    /// Forces a reannounce for the trackers of the torrents with the given hashes.
    ///
    /// This is a `core.force_reannounce` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to force a reannounce on.
    static func reannounce(hashes: [String]) -> Request<Void> {
        .rpc(.init(method: "core.force_reannounce", params: [hashes]))
    }

    /// Moves the storage for torrents with the given hashes.
    ///
    /// This is a `core.move_storage` request.
    ///
    /// - Parameters:
    ///   - hashes: The torrent hashes whose storage should be moved.
    ///   - path: The new path where the torrents' data should be stored.
    static func moveStorage(hashes: [String], path: String) -> Request<Void> {
        .rpc(.init(method: "core.move_storage", params: [hashes, path]))
    }
}
