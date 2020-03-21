import Combine
import Deluge
import Foundation
import Preferences
import ViewModel

final class DelugeTorrentListViewModelImplementation: StandardTorrentListViewModelImplementation, TorrentRefresher {
    private let client: DelugeClient
    private let updatedSubject = PassthroughSubject<([DelugeTorrent], [DelugeLabel]), Never>()

    var updated: AnyPublisher<([DelugeTorrent], [DelugeLabel]), Never> {
        updatedSubject.eraseToAnyPublisher()
    }

    init(client: DelugeClient) {
        self.client = client
    }

    func refresh() -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), Error> {
        client.request(.updateUIForApp).eraseError().eraseToAnyPublisher()
    }

    func detailViewModel(
        for torrent: CurrentValueSubject<DelugeTorrent, Never>,
        labels: CurrentValueSubject<[DelugeLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = DelugeTorrentDetailViewModelImplementation(client: client, refresher: self)
        let viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels
        )
        return AnyViewModel(viewModel)
    }

    func addLink(_ url: String) -> AnyPublisher<(String, String), Never> {
        guard let url = URL(string: url) else {
            return Just((L10n.torrentLinkValidationError, L10n.torrentLinkValidationErrorDescription))
                .eraseToAnyPublisher()
        }

        let publisher: AnyPublisher<Void, DelugeError>

        if url.scheme == "magnet" {
            publisher = client.request(.add(magnetURL: url)).asVoid().eraseToAnyPublisher()
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
        client.request(.pause(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    func resume(_ torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.resume(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    func remove(_ torrents: [DelugeTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData))
            .asVoid()
            .eraseError()
            .eraseToAnyPublisher()
    }

    func verify(_ torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.recheck(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    func setLabel(_ label: DelugeLabel, for torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        let requests = torrents.map {
            client.request(.setLabel(hash: $0.hash, label: label.name)).eraseError()
        }
        return Publishers.MergeMany(requests)
            .collect()
            .asVoid()
            .eraseToAnyPublisher()
    }

    func updateTrackers(for torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrents: [DelugeTorrent], to path: String) -> AnyPublisher<Void, Error> {
        client.request(.move(hashes: torrents.map(\.hash), path: path))
            .eraseError()
            .eraseToAnyPublisher()
    }

    func refreshTorrents() -> AnyPublisher<Void, Error> {
        client.request(.updateUIForApp)
            .handleEvents(receiveOutput: { [weak self] in
                self?.updatedSubject.send($0)
            })
            .asVoid()
            .eraseError()
            .eraseToAnyPublisher()
    }
}
