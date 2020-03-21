import Combine
import Foundation
import Preferences
import Transmission
import ViewModel

// swiftlint:disable:next line_length
final class TransmissionTorrentListViewModelImplementation: StandardTorrentListViewModelImplementation, TorrentRefresher {
    private let client: TransmissionClient
    private let updatedSubject = PassthroughSubject<[TransmissionTorrent], Never>()

    var updated: AnyPublisher<([TransmissionTorrent], [Never]), Never> {
        updatedSubject.map { ($0, []) }.eraseToAnyPublisher()
    }

    init(client: TransmissionClient) {
        self.client = client
    }

    func refresh() -> AnyPublisher<([TransmissionTorrent], [Never]), Error> {
        client.request(.torrentsForApp)
            .map { ($0, []) }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func detailViewModel(
        for torrent: CurrentValueSubject<TransmissionTorrent, Never>,
        labels: CurrentValueSubject<[Never], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: self)
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

        return client.request(.add(url: url))
            .ignoreOutput()
            .map { _ in ("", "") }
            .catch { error -> AnyPublisher<(String, String), Never> in
                Just((L10n.addTorrentError, error.localizedDescription)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func pause(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.stop(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.start(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrents: [TransmissionTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        client.request(.remove(ids: torrents.map(\.hash), removeData: removeData))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.verify(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: Never, for torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {}

    func updateTrackers(for torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrents: [TransmissionTorrent], to path: String) -> AnyPublisher<Void, Error> {
        client.request(.move(ids: torrents.map(\.hash), path: path))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func refreshTorrents() -> AnyPublisher<Void, Error> {
        client.request(.torrentsForApp)
            .handleEvents(receiveOutput: { [weak self] torrents in
                self?.updatedSubject.send(torrents)
            })
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}
