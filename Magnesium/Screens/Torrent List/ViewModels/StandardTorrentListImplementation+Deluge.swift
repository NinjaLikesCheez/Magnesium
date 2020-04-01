import Combine
import Deluge
import Foundation
import ViewModel

extension StandardTorrentListImplementation where Torrent == DelugeTorrent, Label == DelugeLabel {
    static func deluge(_ session: DelugeSession) -> Self {
        let client = session.client
        let updatePublisher = Publishers.CombineLatest(session.torrents, session.labels)
            .dropFirst()
            .eraseToAnyPublisher()
        return .init(
            updated: updatePublisher,
            refresh: { refresh(session: session) },
            detailViewModel: { detailViewModel(session: session, torrent: $0, labels: $1) },
            addLink: { addLink(client: client, url: $0) },
            pause: { pause(client: client, torrents: $0) },
            resume: { resume(client: client, torrents: $0) },
            remove: { remove(client: client, torrents: $0, removeData: $1) },
            verify: { verify(client: client, torrents: $0) },
            setLabel: { setLabel(client: client, label: $0, torrents: $1) },
            updateTrackers: { updateTrackers(client: client, torrents: $0) },
            moveDownloadFolder: { moveDownloadFolder(client: client, path: $0, torrents: $1) }
        )
    }

    private static func refresh(session: DelugeSession) -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), Error> {
        session.refresh()
    }

    private static func detailViewModel(
        session: DelugeSession,
        torrent: CurrentValueSubject<DelugeTorrent, Never>,
        labels: CurrentValueSubject<[DelugeLabel], Never>
    ) -> AnyTorrentDetailViewModel {
        let viewModel = StandardTorrentDetailViewModel(
            implementation: .deluge(session: session),
            torrent: torrent,
            labels: labels
        )
        return AnyViewModel(viewModel)
    }

    private static func addLink(
        client: DelugeClient,
        url: String
    ) -> AnyPublisher<Void, AddLinkError> {
        guard let url = URL(string: url) else {
            return Fail(error: .init(
                title: L10n.torrentLinkValidationError,
                message: L10n.torrentLinkValidationErrorDescription
            )).eraseToAnyPublisher()
        }

        let publisher: AnyPublisher<Void, DelugeError>

        if url.scheme == "magnet" {
            publisher = client.request(.add(magnetURL: url)).asVoid().eraseToAnyPublisher()
        } else {
            publisher = client.request(.add(url: url))
        }

        return publisher
            .mapError { error in
                .init(title: L10n.addTorrentError, message: error.localizedDescription)
            }
            .eraseToAnyPublisher()
    }

    private static func pause(client: DelugeClient, torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.pause(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func resume(client: DelugeClient, torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.resume(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func remove(
        client: DelugeClient,
        torrents: [DelugeTorrent],
        removeData: Bool
    ) -> AnyPublisher<Void, Error> {
        client.request(.remove(hashes: torrents.map(\.hash), removeData: removeData))
            .asVoid()
            .eraseError()
            .eraseToAnyPublisher()
    }

    private static func verify(client: DelugeClient, torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.recheck(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func setLabel(
        client: DelugeClient,
        label: DelugeLabel,
        torrents: [DelugeTorrent]
    ) -> AnyPublisher<Void, Error> {
        let requests = torrents.map {
            client.request(.setLabel(hash: $0.hash, label: label.name)).eraseError()
        }
        return Publishers.MergeMany(requests).collect().asVoid().eraseToAnyPublisher()
    }

    private static func updateTrackers(client: DelugeClient, torrents: [DelugeTorrent]) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(hashes: torrents.map(\.hash))).eraseError().eraseToAnyPublisher()
    }

    private static func moveDownloadFolder(
        client: DelugeClient,
        path: String,
        torrents: [DelugeTorrent]
    ) -> AnyPublisher<Void, Error> {
        client.request(.move(hashes: torrents.map(\.hash), path: path)).eraseError().eraseToAnyPublisher()
    }
}
