public extension Request {
    /// Requests the list of torrents.
    ///
    /// RPC Method: `torrent-get`
    ///
    /// - Parameter properties: The torrent properties to include.
    static func torrents(properties: [Torrent.PropertyKeys]) -> Request<[Torrent]> {
        .init(
            method: "torrent-get",
            args: ["fields": properties.map(\.rawValue)],
            transform: { response in
                guard let arguments = response["arguments"] as? [String: Any],
                    let torrents = arguments["torrents"] as? [[String: Any]]
                else {
                    return .failure(.unexpectedResponse)
                }

                return .success(torrents.compactMap(Torrent.init))
            }
        )
    }

    /*
     let fields = ["files", "fileStats"]
     return request(method: "torrent-get", args: ["ids": [id], "fields": fields])
     .flatMap { response -> AnyPublisher<[TorrentFile], Error> in
     guard let arguments = response["arguments"] as? [String: Any],
     let torrents = arguments["torrents"] as? [[String: Any]],
     !torrents.isEmpty,
     let filesDict = torrents[0]["files"] as? [[String: Any]],
     let statsDict = torrents[0]["fileStats"] as? [[String: Any]]
     else {
     return Fail(error: .unexpectedResponse).eraseToAnyPublisher()
     }

     let files = zip(filesDict, statsDict).enumerated().compactMap { index, element in
     TorrentFile(index: index, file: element.0, stats: element.1)
     }
     return Just(files)
     .setFailureType(to: Error.self)
     .eraseToAnyPublisher()
     }
     .eraseToAnyPublisher()
     */
    /// Requests the list of files for a torrents.
    ///
    /// RPC Method: `torrent-get`
    ///
    /// - Parameter ids: The torrent IDs and/or hashes to remove.
    static func torrentFiles(id: Any) -> Request<[TorrentFile]> {
        .init(
            method: "torrent-get",
            args: ["ids": [id], "fields": ["files", "fileStats"]],
            transform: { response -> Result<[TorrentFile], TransmissionError> in
                guard let arguments = response["arguments"] as? [String: Any],
                    let torrents = arguments["torrents"] as? [[String: Any]],
                    !torrents.isEmpty,
                    let filesDict = torrents[0]["files"] as? [[String: Any]],
                    let statsDict = torrents[0]["fileStats"] as? [[String: Any]]
                else {
                    return .failure(.unexpectedResponse)
                }

                return .success(zip(filesDict, statsDict).enumerated().compactMap { index, element in
                    TorrentFile(index: index, file: element.0, stats: element.1)
                })
            }
        )
    }
}
