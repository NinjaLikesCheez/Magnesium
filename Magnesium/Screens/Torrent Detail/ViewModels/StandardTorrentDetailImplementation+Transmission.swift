import Combine

extension StandardTorrentDetailImplementation {
    static func transmission(session: TransmissionSession) -> Self {
        let client = session.client
        return .init(
            refresh: { refresh(session: session) },
            refreshFiles: { refreshFiles(client: client, torrent: $0) },
            pause: { pause(client: client, torrent: $0) },
            resume: { resume(client: client, torrent: $0) },
            remove: { remove(client: client, torrent: $0, removeData: $1) },
            verify: { verify(client: client, torrent: $0) },
            setLabel: { _, _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() },
            updateTrackers: { updateTrackers(client: client, torrent: $0) },
            moveDownloadFolder: { moveDownloadFolder(client: client, path: $0, torrent: $1) }
        )
    }

    private static func refresh(session: TransmissionSession) -> AnyPublisher<Void, Error> {
        session.refresh().asVoid().eraseToAnyPublisher()
    }

    private static func refreshFiles(
        client: TransmissionClient,
        torrent: StandardTorrent
    ) -> AnyPublisher<[StandardTorrentFile], Error> {
        client.request(.torrentFiles(id: torrent.hash)).map { $0.map(\.standard) }.eraseError().eraseToAnyPublisher()
    }

    private static func pause(client: TransmissionClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.stop(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func resume(client: TransmissionClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.start(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func remove(
        client: TransmissionClient,
        torrent: StandardTorrent,
        removeData: Bool
    ) -> AnyPublisher<Void, Error> {
        client.request(.remove(ids: [torrent.hash], removeData: removeData)).eraseError().eraseToAnyPublisher()
    }

    private static func verify(client: TransmissionClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.verify(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func updateTrackers(
        client: TransmissionClient,
        torrent: StandardTorrent
    ) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func moveDownloadFolder(
        client: TransmissionClient,
        path: String,
        torrent: StandardTorrent
    ) -> AnyPublisher<Void, Error> {
        client.request(.move(ids: [torrent.hash], path: path)).eraseError().eraseToAnyPublisher()
    }
}
