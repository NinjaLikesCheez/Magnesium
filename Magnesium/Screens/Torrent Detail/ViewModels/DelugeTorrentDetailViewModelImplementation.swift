import Combine
import Deluge

final class DelugeTorrentDetailViewModelImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = DelugeTorrent
    typealias Label = DelugeLabel
    typealias File = DelugeTorrentFile

    private let client: DelugeClient
    private let refresher: DelugeRefreshable

    init(client: DelugeClient, refresher: DelugeRefreshable) {
        self.client = client
        self.refresher = refresher
    }

    private func torrentFiles(in items: [Deluge.TorrentItem]) -> [DelugeTorrentFile] {
        items.reduce(into: [DelugeTorrentFile]()) { result, item in
            switch item {
            case let .file(file):
                result.append(file)
            case let .directory(_, items):
                result.append(contentsOf: torrentFiles(in: items))
            }
        }
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshDeluge().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func updateFiles(_ torrent: DelugeTorrent) -> AnyPublisher<[DelugeTorrentFile], Error> {
        return client.request(.torrentItems(hash: torrent.hash))
            .map(torrentFiles(in:))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func pause(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.pause(hashes: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.resume(hashes: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrent: DelugeTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.request(.remove(hashes: [torrent.hash], removeData: removeData))
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.recheck(hashes: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: DelugeLabel, for torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.setLabel(hash: torrent.hash, label: label.name))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func updateTrackers(for torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        return client.request(.reannounce(hashes: [torrent.hash])).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrent: DelugeTorrent, to path: String) -> AnyPublisher<Void, Error> {
        return client.request(.moveStorage(hashes: [torrent.hash], path: path))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
