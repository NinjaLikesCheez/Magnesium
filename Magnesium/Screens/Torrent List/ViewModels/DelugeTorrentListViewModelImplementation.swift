import Combine
import Deluge
import Foundation
import Preferences
import ViewModel

final class DelugeTorrentListViewModelImplementation: StandardTorrentListViewModelImplementation, TorrentRefresher {
    private let client: DelugeClient
    private let preferences: Preferences
    private let updatedSubject = PassthroughSubject<([DelugeTorrent], [DelugeLabel]), Never>()

    var updated: AnyPublisher<([DelugeTorrent], [DelugeLabel]), Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    init(client: DelugeClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), Error> {
        client.request(.updateUIForApp).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func detailViewModel(
        for torrent: CurrentValueSubject<DelugeTorrent, Never>,
        labels: CurrentValueSubject<[DelugeLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = DelugeTorrentDetailViewModelImplementation(client: client, refresher: self)
        let viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels,
            preferences: preferences
        )
        return AnyEmitterViewModel(viewModel)
    }

    func addLink(_ url: String) -> AnyPublisher<(String, String), Never> {
        guard let url = URL(string: url) else {
            return Just((L10n.torrentLinkValidationError, L10n.torrentLinkValidationErrorDescription))
                .eraseToAnyPublisher()
        }

        let publisher: AnyPublisher<Void, DelugeError>

        if url.scheme == "magnet" {
            publisher = client.request(.add(magnetURL: url)).map { _ in () }.eraseToAnyPublisher()
        } else {
            publisher = client.request(.add(url: url))
        }

        return publisher
            .ignoreOutput()
            .map { _ in ("", "") }
            .catch { error -> AnyPublisher<(String, String), Never> in
                Just((L10n.addTorrentError, error.localizedDescription)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func pause(_ torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.pause(hashes: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.resume(hashes: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrents: [DelugeTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData))
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.recheck(hashes: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: DelugeLabel, for torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        let requests = torrents.map {
            client.request(.setLabel(hash: $0.hash, label: label.name)).mapError { $0 as Error }
        }
        return Publishers.MergeMany(requests)
            .collect()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func updateTrackers(for torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(hashes: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrents: [DelugeTorrent], to path: String) -> AnyPublisher<Void, Error> {
        client.request(.move(hashes: torrents.map(\.hash), path: path))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func refreshTorrents() -> AnyPublisher<Void, Error> {
        client.request(.updateUIForApp)
            .handleEvents(receiveOutput: { [weak self] in
                self?.updatedSubject.send($0)
            })
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
