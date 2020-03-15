import Combine
import Transmission

final class TransmissionTorrentDetailViewModelImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = TransmissionTorrent
    typealias Label = NeverLabel
    typealias File = TransmissionTorrentFile

    private let client: TransmissionClient
    private let refresher: TransmissionRefreshable

    init(client: TransmissionClient, refresher: TransmissionRefreshable) {
        self.client = client
        self.refresher = refresher
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshTransmission().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func updateFiles(_ torrent: TransmissionTorrent) -> AnyPublisher<[TransmissionTorrentFile], Error> {
        return client.request(.torrentFiles(id: torrent.hash)).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func pause(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.stop(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.start(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrent: TransmissionTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.request(.remove(ids: [torrent.hash], removeData: removeData))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.verify(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: NeverLabel, for torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {}

    func updateTrackers(for torrent: TransmissionTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.reannounce(ids: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrent: TransmissionTorrent, to path: String) -> AnyPublisher<Void, Error> {
        return client.request(.move(ids: [torrent.hash], path: path))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
