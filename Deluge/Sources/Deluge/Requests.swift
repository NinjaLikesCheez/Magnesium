import Foundation

// MARK: - Void

public extension Request where Value == Void {
    /// Attempts to authenticate with the server.
    ///
    /// This is an `auth.login` RPC request.
    static var authenticate: Self {
        return .rpc(.init(
            method: "auth.login",
            authenticateIfNeeded: false,
            prepare: { request, client in
                var request = request
                request.params = [client.password]
                return request
            },
            transform: { response -> Result<Value, Client.Error> in
                let authenticated = response["result"] as? Bool ?? false
                guard authenticated else {
                    return .failure(.unauthenticated)
                }

                return .success(())
            }
        ))
    }

    /// Resumes torrents with the given hashes.
    ///
    /// This is a `core.resume_torrent` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to resume.
    static func resume(hashes: [String]) -> Self {
        .rpc(.init(method: "core.resume_torrent", params: [hashes]))
    }

    /// Pauses torrents with the given hashes.
    ///
    /// This is a `core.pause_torrent` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to pause.
    static func pause(hashes: [String]) -> Self {
        .rpc(.init(method: "core.pause_torrent", params: [hashes]))
    }

    /// Removes torrents with the given hashes.
    ///
    /// This is a `core.remove_torrents` RPC request.
    ///
    /// - Parameters:
    ///   - hashes: The torrent hashes to remove.
    ///   - removeData: Whether the torrents' data should be removed.
    static func remove(hashes: [String], removeData: Bool) -> Self {
        .rpc(.init(method: "core.remove_torrents", params: [hashes, removeData]))
    }

    /// Rechecks torrents with the given hashes.
    ///
    /// This is a `core.force_recheck` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to recheck.
    static func recheck(hashes: [String]) -> Self {
        .rpc(.init(method: "core.force_recheck", params: [hashes]))
    }

    /// Forces a reannounce for the trackers of the torrents with the given hashes.
    ///
    /// This is a `core.force_reannounce` RPC request.
    ///
    /// - Parameter hashes: The torrent hashes to force a reannounce on.
    static func reannounce(hashes: [String]) -> Self {
        .rpc(.init(method: "core.force_reannounce", params: [hashes]))
    }

    /// Moves the storage for torrents with the given hashes.
    ///
    /// This is a `core.move_storage` request.
    ///
    /// - Parameters:
    ///   - hashes: The torrent hashes whose storage should be moved.
    ///   - path: The new path where the torrents' data should be stored.
    static func moveStorage(hashes: [String], path: String) -> Self {
        .rpc(.init(method: "core.move_storage", params: [hashes, path]))
    }

    /// Adds a torrent using a web URL to a torrent file.
    ///
    /// This is a `core.add_torrent_url` RPC request.
    ///
    /// - Parameter url: A web URL to a torrent file.
    static func add(url: URL) -> Self {
        .rpc(.init(method: "core.add_torrent_url", params: [url.absoluteString, [String: Any]()]))
    }

    /// Adds a torrent using a magnet URL.
    ///
    /// This is a `core.add_torrent_magnet` RPC request.
    ///
    /// - Parameter url: A magnet URL.
    static func add(magnetURL: URL) -> Self {
        .rpc(.init(method: "core.add_torrent_magnet", params: [magnetURL.absoluteString, [String: Any]()]))
    }

    /// Adds a torrent using a local file URL to a torrent file.
    ///
    /// This is an upload request and a `web.add_torrents` RPC request.
    ///
    /// - Parameter fileURL: A local file URL to a torrent file.
    static func add(fileURL: URL) -> Self {
        .upload(.init(
            fileURL: fileURL,
            mimeType: "application/x-bittorrent",
            transform: { response -> Transform<Value> in
                guard let path = (response["files"] as? [String])?.first else {
                    return .result(.failure(.unexpectedResponse))
                }

                return .request(.rpc(.init(
                    method: "web.add_torrents",
                    params: [[["path": path, "options": [String: Any]()]]]
                )))
            }
        ))
    }

    /// Sets the label for a torrent.
    ///
    /// This is a `label.set_torrent` RPC request.
    ///
    /// - Parameters:
    ///   - hash: The hash of the torrent whose label should be set.
    ///   - label: The name of the label to set.
    static func setLabel(hash: String, label: String) -> Self {
        .rpc(.init(method: "label.set_torrent", params: [hash, label]))
    }
}

// MARK: - ([Torrent], [Label])

public extension Request where Value == ([Torrent], [Label]) {
    /// Parses the labels out of a `web.update_ui` response.
    /// - Parameter response: The response dictionary.
    /// - Returns: The list of labels or an empty array if the response could not be parsed.
    private static func parseLabels(from response: [String: Any]) -> [Label] {
        guard let filters = response["filters"] as? [String: Any],
            let labels = filters["label"] as? [[AnyObject]]
        else {
            return []
        }

        return labels.compactMap { pair in
            guard pair.count == 2, let name = pair[0] as? String, name != "All", let count = pair[1] as? Int else {
                return nil
            }

            return Label(name: name, count: count)
        }
    }

    /// Parses the torrents and labels out of a `web.update_ui` response.
    /// - Parameter response: The response dictionary.
    /// - Returns: A `Result` containing either the list of torrents and labels, or an `Error` if the response
    /// dictionary could not be parsed.
    private static func parseUpdateUIResponse(_ response: [String: Any]) -> Result<Value, Client.Error> {
        guard let results = response["result"] as? [String: Any],
            let torrents = results["torrents"] as? [String: [String: Any]]
        else {
            return .failure(.unexpectedResponse)
        }

        let labels = Self.parseLabels(from: results)
        return .success((torrents.compactMap { Torrent(hash: $0.key, dictionary: $0.value) }, labels))
    }

    /// Requests the list of torrents and labels from the server.
    ///
    /// This is a `web.update_ui` RPC request.
    ///
    /// - Parameter properties: The torrent properties to include.
    static func currentState(properties: [String]) -> Self {
        .rpc(.init(method: "web.update_ui", params: [properties, []], transform: parseUpdateUIResponse))
    }
}

// MARK: - [TorrentItem]

public extension Request where Value == [TorrentItem] {
    /// Parses the items out of a `web.get_torrent_files` response.
    /// - Parameter response: The response dictionary.
    /// - Returns: A `Result` containing either the list of items or an `Error` if the response dictionary could
    /// not be parsed.
    private static func parseTorrentFilesResponse(_ response: [String: Any]) -> Result<[TorrentItem], Client.Error> {
        guard let results = response["result"] as? [String: Any],
            let contents = results["contents"] as? [String: [String: Any]]
        else {
            return .failure(.unexpectedResponse)
        }

        func parseDirectory(_ contents: [String: [String: Any]]) -> [TorrentItem] {
            var items = [TorrentItem]()
            for (name, node) in contents {
                guard let type = node["type"] as? String else { continue }
                switch type {
                case "dir":
                    guard let child = node["contents"] as? [String: [String: Any]] else { break }
                    items.append(.directory(name: name, items: parseDirectory(child)))
                case "file":
                    guard let file = TorrentFile(name: name, dictionary: node) else { break }
                    items.append(.file(file))
                default:
                    break
                }
            }
            return items
        }

        return .success(parseDirectory(contents))
    }

    /// Requests the list of items in a torrent.
    ///
    /// This is a `web.get_torrent_files` RPC request.
    ///
    /// - Parameter hash: The hash of the torrent whose items should be requested.
    static func torrentItems(hash: String) -> Self {
        .rpc(.init(method: "web.get_torrent_files", params: [hash], transform: parseTorrentFilesResponse))
    }
}
