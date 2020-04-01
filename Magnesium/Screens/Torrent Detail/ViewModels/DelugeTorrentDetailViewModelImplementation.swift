import Combine

final class DelugeTorrentDetailViewModelImplementation: StandardTorrentDetailViewModelImplementation {
    typealias Torrent = DelugeTorrent
    typealias Label = DelugeLabel
    typealias File = DelugeTorrentFile

    private let session: DelugeSession

    private var client: DelugeClient {
        session.client
    }

    init(session: DelugeSession) {
        self.session = session
    }

    private func torrentFiles(in items: [DelugeTorrentItem]) -> [DelugeTorrentFile] {
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
        session.refresh().asVoid().eraseToAnyPublisher()
    }

    func updateFiles(_ torrent: DelugeTorrent) -> AnyPublisher<[DelugeTorrentFile], Error> {
        client.request(.torrentItems(hash: torrent.hash))
            .map(torrentFiles(in:))
            .eraseError()
            .eraseToAnyPublisher()
    }

    func pause(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        client.request(.pause(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    func resume(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        client.request(.resume(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    func remove(_ torrent: DelugeTorrent, removeData: Bool) -> AnyPublisher<Void, Error> {
        client.request(.remove(hashes: [torrent.hash], removeData: removeData))
            .asVoid()
            .eraseError()
            .eraseToAnyPublisher()
    }

    func verify(_ torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        client.request(.recheck(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    func setLabel(_ label: DelugeLabel, for torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        client.request(.setLabel(hash: torrent.hash, label: label.name))
            .eraseError()
            .eraseToAnyPublisher()
    }

    func updateTrackers(for torrent: DelugeTorrent) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(hashes: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrent: DelugeTorrent, to path: String) -> AnyPublisher<Void, Error> {
        client.request(.move(hashes: [torrent.hash], path: path))
            .eraseError()
            .eraseToAnyPublisher()
    }
}
