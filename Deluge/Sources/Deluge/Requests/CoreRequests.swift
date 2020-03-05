import Foundation

public extension Request {
    /// Adds a torrent using a local file URL to a torrent file.
    ///
    /// This is a `core.add_torrent_file` RPC request.
    ///
    /// - Parameter fileURL: A local file URL to a torrent file.
    /// - Returns: The added torrent's hash.
    static func add(fileURL: URL) -> Request<String> {
        let fileName = fileURL.lastPathComponent
        let data = FileManager.default.contents(atPath: fileURL.path)?.base64EncodedString() ?? ""
        return .init(
            method: "core.add_torrent_file",
            params: [fileName, data, [String: Any]()],
            transform: { response in
                guard let hash = response["result"] as? String else { return .failure(.unexpectedResponse) }
                return .success(hash)
            }
        )
    }

    /// Adds multiple torrents using a local file URLs to torrent files.
    ///
    /// This is a `core.add_torrent_files` RPC request.
    ///
    /// - Parameter fileURLs: An array of local file URLs to torrent files.
    static func add(fileURLs: [URL]) -> Request<Void> {
        let files = fileURLs.map { url -> [Any] in
            let fileName = url.lastPathComponent
            let data = FileManager.default.contents(atPath: url.path)?.base64EncodedString() ?? ""
            return [fileName, data, [String: Any]()]
        }
        return .init(method: "core.add_torrent_files", params: [files])
    }

    /// Adds a torrent using a magnet URL.
    ///
    /// This is a `core.add_torrent_magnet` RPC request.
    ///
    /// - Parameter url: A magnet URL.
    /// - Returns: The added torrent's hash.
    static func add(magnetURL: URL) -> Request<String> {
        .init(
            method: "core.add_torrent_magnet",
            params: [magnetURL.absoluteString, [String: Any]()],
            transform: { response in
                guard let hash = response["result"] as? String else { return .failure(.unexpectedResponse) }
                return .success(hash)
            }
        )
    }

    /// Adds a torrent using a web URL to a torrent file.
    ///
    /// This is a `core.add_torrent_url` RPC request.
    ///
    /// - Parameter url: A web URL to a torrent file.
    static func add(url: URL) -> Request<Void> {
        .init(method: "core.add_torrent_url", params: [url.absoluteString, [String: Any]()])
    }

    /// Forces a reannounce for the trackers of the torrents with the given hashes.
    ///
    /// This is a `core.force_reannounce` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to force a reannounce on.
    static func reannounce(hashes: [String]) -> Request<Void> {
        .init(method: "core.force_reannounce", params: [hashes])
    }

    /// Rechecks torrents with the given hashes.
    ///
    /// This is a `core.force_recheck` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to recheck.
    static func recheck(hashes: [String]) -> Request<Void> {
        .init(method: "core.force_recheck", params: [hashes])
    }

    /// Moves the storage for torrents with the given hashes.
    ///
    /// This is a `core.move_storage` request.
    ///
    /// - Parameters:
    ///   - hashes: The torrent hashes whose storage should be moved.
    ///   - path: The new path where the torrents' data should be stored.
    static func moveStorage(hashes: [String], path: String) -> Request<Void> {
        .init(method: "core.move_storage", params: [hashes, path])
    }

    /// Pauses torrents with the given hashes.
    ///
    /// This is a `core.pause_torrents` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to pause.
    static func pause(hashes: [String]) -> Request<Void> {
        .init(method: "core.pause_torrents", params: [hashes])
    }

    /// Removes torrents with the given hashes.
    ///
    /// This is a `core.remove_torrents` RPC request.
    ///
    /// - Parameters:
    ///   - hashes: The torrent hashes to remove.
    ///   - removeData: Whether the torrents' data should be removed.
    /// - Returns: An array of torrent hash and error messages, or an empty array if no errors occurred.
    static func remove(hashes: [String], removeData: Bool) -> Request<[(hash: String, message: String)]> {
        .init(
            method: "core.remove_torrents",
            params: [hashes, removeData],
            transform: { response in
                guard let errors = response["result"] as? [[String]] else { return .failure(.unexpectedResponse) }
                return .success(errors.map { error -> (String, String) in
                    (error.first ?? "", error.count > 1 ? error[1] : "")
                })
            }
        )
    }

    /// Resumes torrents with the given hashes.
    ///
    /// This is a `core.resume_torrents` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to resume.
    static func resume(hashes: [String]) -> Request<Void> {
        .init(method: "core.resume_torrents", params: [hashes])
    }
}
