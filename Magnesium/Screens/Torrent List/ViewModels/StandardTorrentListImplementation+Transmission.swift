import Combine
import Foundation
import Preferences
import ViewModel

extension StandardTorrentListImplementation where Torrent == TransmissionTorrent, Label == Never {
    static func transmission(_ session: TransmissionSession) -> Self {
        let client = session.client
        return .init(
            updated: session.torrents.dropFirst().map { ($0, []) }.eraseToAnyPublisher(),
            refresh: { refresh(session: session) },
            detailViewModel: { detailViewModel(session: session, torrent: $0, labels: $1) },
            addLink: { addLink(client: client, url: $0) },
            pause: { pause(client: client, torrents: $0) },
            resume: { resume(client: client, torrents: $0) },
            remove: { remove(client: client, torrents: $0, removeData: $1) },
            verify: { verify(client: client, torrents: $0) },
            setLabel: { _, _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() },
            updateTrackers: { updateTrackers(client: client, torrents: $0) },
            moveDownloadFolder: { moveDownloadFolder(client: client, path: $0, torrents: $1) }
        )
    }

    private static func refresh(session: TransmissionSession) -> AnyPublisher<([TransmissionTorrent], [Never]), Error> {
        session.refresh().map { ($0, []) }.eraseToAnyPublisher()
    }

    private static func detailViewModel(
        session: TransmissionSession,
        torrent: CurrentValueSubject<TransmissionTorrent, Never>,
        labels: CurrentValueSubject<[Never], Never>
    ) -> AnyTorrentDetailViewModel {
        let implementation = TransmissionTorrentDetailViewModelImplementation(session: session)
        let viewModel = StandardTorrentDetailViewModel(
            implementation: implementation,
            torrent: torrent,
            labels: labels
        )
        return AnyViewModel(viewModel)
    }

    private static func addLink(
        client: TransmissionClient,
        url: String
    ) -> AnyPublisher<Void, AddLinkError> {
        guard let url = URL(string: url) else {
            return Fail(error: .init(
                title: L10n.torrentLinkValidationError,
                message: L10n.torrentLinkValidationErrorDescription
            )).eraseToAnyPublisher()
        }

        return client.request(.add(url: url))
            .mapError { error in
                .init(title: L10n.addTorrentError, message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    private static func pause(
        client: TransmissionClient,
        torrents: [TransmissionTorrent]
    ) -> AnyPublisher<Void, Error> {
        client.request(.stop(ids: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func resume(
        client: TransmissionClient,
        torrents: [TransmissionTorrent]
    ) -> AnyPublisher<Void, Error> {
        client.request(.start(ids: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func remove(
        client: TransmissionClient,
        torrents: [TransmissionTorrent],
        removeData: Bool
    ) -> AnyPublisher<Void, Error> {
        client.request(.remove(ids: torrents.map(\.hash), removeData: removeData))
            .eraseError()
            .eraseToAnyPublisher()
    }

    private static func verify(
        client: TransmissionClient,
        torrents: [TransmissionTorrent]
    ) -> AnyPublisher<Void, Error> {
        client.request(.verify(ids: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func updateTrackers(
        client: TransmissionClient,
        torrents: [TransmissionTorrent]
    ) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(ids: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func moveDownloadFolder(
        client: TransmissionClient,
        path: String,
        torrents: [TransmissionTorrent]
    ) -> AnyPublisher<Void, Error> {
        client.request(.move(ids: torrents.map(\.hash), path: path)).eraseError().eraseToAnyPublisher()
    }
}
