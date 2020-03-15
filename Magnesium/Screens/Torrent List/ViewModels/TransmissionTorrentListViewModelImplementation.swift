import Combine
import Foundation
import Preferences
import Transmission
import ViewModel

// swiftlint:disable:next line_length
final class TransmissionTorrentListViewModelImplementation: StandardTorrentListViewModelImplementation, TransmissionRefreshable {
    private let client: TransmissionClient
    private let preferences: Preferences
    private let updatedSubject = PassthroughSubject<[TransmissionTorrent], Never>()

    var updated: AnyPublisher<([TransmissionTorrent], [NeverLabel]), Never> {
        return updatedSubject.map { ($0, []) }.eraseToAnyPublisher()
    }

    init(client: TransmissionClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
    }

    func refresh() -> AnyPublisher<([TransmissionTorrent], [NeverLabel]), Error> {
        return client.request(.torrentsForApp)
            .map { ($0, []) }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func detailViewModel(
        for torrent: CurrentValueSubject<TransmissionTorrent, Never>,
        labels: CurrentValueSubject<[NeverLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = TransmissionTorrentDetailViewModelImplementation(client: client, refresher: self)
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

        return client.request(.add(url: url))
            .ignoreOutput()
            .map { _ in ("", "") }
            .catch { error -> AnyPublisher<(String, String), Never> in
                return Just((L10n.addTorrentError, error.localizedDescription)).eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func pause(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.request(.stop(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.request(.start(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(_ torrents: [TransmissionTorrent], removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.request(.remove(ids: torrents.map(\.hash), removeData: removeData))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func verify(_ torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.request(.verify(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func setLabel(_ label: NeverLabel, for torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {}

    func updateTrackers(for torrents: [TransmissionTorrent]) -> AnyPublisher<Void, Error> {
        return client.request(.reannounce(ids: torrents.map(\.hash))).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func moveDownloadFolder(for torrents: [TransmissionTorrent], to path: String) -> AnyPublisher<Void, Error> {
        return client.request(.move(ids: torrents.map(\.hash), path: path))
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func refreshTransmission() -> AnyPublisher<Void, TransmissionError> {
        return client.request(.torrentsForApp)
            .handleEvents(receiveOutput: { [weak self] torrents in
                self?.updatedSubject.send(torrents)
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
