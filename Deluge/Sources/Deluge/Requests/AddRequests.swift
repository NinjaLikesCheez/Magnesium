import Foundation

public extension Request {
    /// Adds a torrent using a web URL to a torrent file.
    ///
    /// This is a `core.add_torrent_url` RPC request.
    ///
    /// - Parameter url: A web URL to a torrent file.
    static func add(url: URL) -> Request<Void> {
        .rpc(.init(method: "core.add_torrent_url", params: [url.absoluteString, [String: Any]()]))
    }

    /// Adds a torrent using a magnet URL.
    ///
    /// This is a `core.add_torrent_magnet` RPC request.
    ///
    /// - Parameter url: A magnet URL.
    static func add(magnetURL: URL) -> Request<Void> {
        .rpc(.init(method: "core.add_torrent_magnet", params: [magnetURL.absoluteString, [String: Any]()]))
    }

    /// Adds a torrent using a local file URL to a torrent file.
    ///
    /// This is an upload request and a `web.add_torrents` RPC request.
    ///
    /// - Parameter fileURL: A local file URL to a torrent file.
    static func add(fileURL: URL) -> Request<Void> {
        .upload(.init(
            fileURL: fileURL,
            mimeType: "application/x-bittorrent",
            transform: { response -> Transformed<Void> in
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
}
