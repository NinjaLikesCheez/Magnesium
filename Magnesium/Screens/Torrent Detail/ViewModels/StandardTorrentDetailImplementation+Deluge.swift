import Combine

extension StandardTorrentDetailImplementation {
    static func deluge(session: DelugeSession) -> Self {
        let client = session.client
        return .init(
            refresh: { refresh(session: session) },
            refreshFiles: { refreshFiles(client: client, torrent: $0) },
            pause: { pause(client: client, torrent: $0) },
            resume: { resume(client: client, torrent: $0) },
            remove: { remove(client: client, torrent: $0, removeData: $1) },
            verify: { verify(client: client, torrent: $0) },
            setLabel: { setLabel(client: client, label: $0, torrent: $1) },
            updateTrackers: { updateTrackers(client: client, torrent: $0) },
            moveDownloadFolder: { moveDownloadFolder(client: client, path: $0, torrent: $1) }
        )
    }

    private static func torrentFiles(in items: [DelugeTorrentItem]) -> [StandardTorrentFile] {
        items.reduce(into: [StandardTorrentFile]()) { result, item in
            switch item {
            case let .file(file):
                result.append(file.standard)
            case let .directory(_, items):
                result.append(contentsOf: torrentFiles(in: items))
            }
        }
    }

    private static func refresh(session: DelugeSession) -> AnyPublisher<Void, Error> {
        session.refresh().asVoid().eraseToAnyPublisher()
    }

    private static func refreshFiles(
        client: DelugeClient,
        torrent: StandardTorrent
    ) -> AnyPublisher<[StandardTorrentFile], Error> {
        client.request(.torrentItems(hash: torrent.hash))
            .map(torrentFiles(in:))
            .eraseError()
            .eraseToAnyPublisher()
    }

    private static func pause(client: DelugeClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.pause(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func resume(client: DelugeClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.resume(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func remove(
        client: DelugeClient,
        torrent: StandardTorrent,
        removeData: Bool
    ) -> AnyPublisher<Void, Error> {
        client.request(.remove(hashes: [torrent.hash], removeData: removeData))
            .asVoid()
            .eraseError()
            .eraseToAnyPublisher()
    }

    private static func verify(client: DelugeClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.recheck(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func setLabel(
        client: DelugeClient,
        label: StandardLabel,
        torrent: StandardTorrent
    ) -> AnyPublisher<Void, Error> {
        client.request(.setLabel(hash: torrent.hash, label: label.name)).eraseError().eraseToAnyPublisher()
    }

    private static func updateTrackers(client: DelugeClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func moveDownloadFolder(
        client: DelugeClient,
        path: String,
        torrent: StandardTorrent
    ) -> AnyPublisher<Void, Error> {
        client.request(.move(hashes: [torrent.hash], path: path)).eraseError().eraseToAnyPublisher()
    }
}
