import Combine

final class TransmissionTorrentDetailViewModelImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = TransmissionTorrent
    typealias Label = Never
    typealias File = TransmissionTorrentFile

    private let client: TransmissionClient
    private let refresher: TorrentRefresher

    init(client: TransmissionClient, refresher: TorrentRefresher) {
        self.client = client
        self.refresher = refresher
    }

    func refresh() -> AnyPublisher<Void, Error> {
        refresher.refreshTorrents()
    }

    func updateFiles(_ torrent: TransmissionTorrent) -> AnyPublisher<[TransmissionTorrentFile], Error> {
        client.request(.torrentFiles(id: torrent.hash)).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func pause(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        client.request(.stop(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        client.request(.start(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrent: TransmissionTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        client.request(.remove(ids: [torrent.hash], removeData: removeData))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        client.request(.verify(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: Never, for torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {}

    func updateTrackers(for torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrent: TransmissionTorrent, to path: String) -> AnyPublisher<Void, Error> {
        client.request(.move(ids: [torrent.hash], path: path))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
