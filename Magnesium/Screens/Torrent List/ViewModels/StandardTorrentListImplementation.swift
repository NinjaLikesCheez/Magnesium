import Combine

struct StandardTorrentListImplementation<Torrent: StandardTorrent, Label: StandardLabel> {
    struct AddLinkError: Error {
        let title: String
        let message: String
    }

    var updated: AnyPublisher<([Torrent], [Label]), Never>
    var refresh: () -> AnyPublisher<([Torrent], [Label]), Error>
    var detailViewModel: (
        CurrentValueSubject<Torrent, Never>,
        CurrentValueSubject<[Label], Never>
    ) -> AnyTorrentDetailViewModel
    var addLink: (String) -> AnyPublisher<Void, AddLinkError>
    var pause: ([Torrent]) -> AnyPublisher<Void, Error>
    var resume: ([Torrent]) -> AnyPublisher<Void, Error>
    var remove: ([Torrent], Bool) -> AnyPublisher<Void, Error>
    var verify: ([Torrent]) -> AnyPublisher<Void, Error>
    var setLabel: (Label, [Torrent]) -> AnyPublisher<Void, Error>
    var updateTrackers: ([Torrent]) -> AnyPublisher<Void, Error>
    var moveDownloadFolder: (String, [Torrent]) -> AnyPublisher<Void, Error>
}
