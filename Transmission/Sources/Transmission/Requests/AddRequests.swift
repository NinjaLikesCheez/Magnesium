import Combine
import Foundation

public extension Request {
    /// Adds a torrent using a web URL to a torrent file or a magnet URL.
    ///
    /// RPC Method: `torrent-add`
    ///
    /// - Parameter url: The web or magnet URL of the torrent to add.
    static func add(url: URL) -> Request<Void> {
        .init(method: "torrent-add", args: ["filename": url.absoluteString])
    }

    /// Adds a torrent using a URL to a local torrent file.
    ///
    /// RPC Method: `torrent-add`
    ///
    /// - Parameter fileURL: The URL of the local torrent file to add.
    static func add(fileURL: URL) -> Request<Void> {
        let data = FileManager.default.contents(atPath: fileURL.path)?.base64EncodedString() ?? ""
        return .init(method: "torrent-add", args: ["metainfo": data])
    }
}
